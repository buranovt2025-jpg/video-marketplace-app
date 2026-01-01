#!/usr/bin/env bash
set -euo pipefail

# Build Flutter Web release bundle (no deploy).
#
# This script is used in:
# - GitHub Actions (pre-flight build)
# - Server deploy script (before rsync to nginx root)
#
# Optional env:
#   FLUTTER_BIN=/opt/flutter/bin/flutter
#   PWA_STRATEGY=none|offline-first (default: none)
#   SKIP_MOBILE_SCANNER_WEB_PATCH=1 (default: 0)

FLUTTER_BIN="${FLUTTER_BIN:-}"
PWA_STRATEGY="${PWA_STRATEGY:-none}"
SKIP_MOBILE_SCANNER_WEB_PATCH="${SKIP_MOBILE_SCANNER_WEB_PATCH:-0}"

resolve_flutter() {
  if [ -n "${FLUTTER_BIN:-}" ] && [ -x "${FLUTTER_BIN:-}" ]; then
    return 0
  fi
  if command -v flutter >/dev/null 2>&1; then
    FLUTTER_BIN="$(command -v flutter)"
    return 0
  fi
  echo "ERROR: Flutter not found. Set FLUTTER_BIN or install flutter." >&2
  exit 1
}

patch_mobile_scanner_web_plugin() {
  if [ "$SKIP_MOBILE_SCANNER_WEB_PATCH" = "1" ]; then
    echo "== mobile_scanner patch skipped (SKIP_MOBILE_SCANNER_WEB_PATCH=1) =="
    return 0
  fi

  # Web build fix:
  # mobile_scanner declares a web plugin that conflicts with dart:html ImageCapture on some SDK versions.
  # Even if app code doesn't use QR scanning on web, Flutter's generated plugin registrant
  # can pull in the web implementation and break compilation.
  #
  # We patch the pub-cache copy of mobile_scanner for the duration of the build
  # by removing the `platforms: web:` block from its pubspec.yaml, then restore afterwards.
  echo "== Patch mobile_scanner web plugin (temporary) =="

  if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 is required for the mobile_scanner patch." >&2
    exit 1
  fi

  local pkg_config=".dart_tool/package_config.json"
  if [ ! -f "$pkg_config" ]; then
    echo "WARN: $pkg_config not found; cannot locate mobile_scanner. Skipping patch." >&2
    return 0
  fi

  local mobile_scanner_dir=""
  mobile_scanner_dir="$(
    python3 - <<'PY'
import json, pathlib, urllib.parse, sys
p = pathlib.Path(".dart_tool/package_config.json")
cfg = json.loads(p.read_text())
for pkg in cfg.get("packages", []):
    if pkg.get("name") == "mobile_scanner":
        uri = pkg.get("rootUri")
        if uri.startswith("file:"):
            path = urllib.parse.urlparse(uri).path
            print(pathlib.Path(path).resolve())
        else:
            print((p.parent / uri).resolve())
        sys.exit(0)
sys.exit(1)
PY
  )" || mobile_scanner_dir=""

  if [ -z "${mobile_scanner_dir:-}" ] || [ ! -f "$mobile_scanner_dir/pubspec.yaml" ]; then
    echo "INFO: mobile_scanner not present; nothing to patch."
    return 0
  fi

  # NOTE:
  # We must not use `local` vars referenced by an EXIT trap with `set -u`,
  # because the trap runs at script exit when locals may be out of scope.
  local ms_pub_path="$mobile_scanner_dir/pubspec.yaml"
  local ms_bak_path="/tmp/mobile_scanner_pubspec.yaml.bak.$$"
  cp "$ms_pub_path" "$ms_bak_path"

  trap "if [ -f \"$ms_bak_path\" ]; then cp \"$ms_bak_path\" \"$ms_pub_path\" || true; rm -f \"$ms_bak_path\" || true; fi" EXIT

  python3 - <<PY
from pathlib import Path

p = Path("$ms_pub_path")
lines = p.read_text().splitlines(True)
out = []
i = 0
while i < len(lines):
    line = lines[i]
    # remove "      web:" block and nested content
    if line.startswith("      web:"):
        i += 1
        while i < len(lines) and lines[i].startswith("        "):
            i += 1
        continue
    out.append(line)
    i += 1
p.write_text("".join(out))
PY

  echo "Patched: $ms_pub_path"
}

echo "== Build Flutter Web =="
resolve_flutter
echo "FLUTTER_BIN=$FLUTTER_BIN"
echo "PWA_STRATEGY=$PWA_STRATEGY"

echo "== Flutter clean/pub get =="
"$FLUTTER_BIN" clean
"$FLUTTER_BIN" pub get

patch_mobile_scanner_web_plugin

echo "== flutter build web --release =="
"$FLUTTER_BIN" build web --release --pwa-strategy="$PWA_STRATEGY"

echo "== Build OK =="

