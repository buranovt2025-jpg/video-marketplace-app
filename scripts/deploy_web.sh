#!/usr/bin/env bash
set -euo pipefail

# Deploy Flutter Web build to nginx static root.
#
# Usage (example):
#   bash scripts/deploy_web.sh
#
# Optional env:
#   PROJECT_DIR=/root/projects/video-marketplace-app
#   WEB_ROOT=/var/www/gogomarket
#   FLUTTER_BIN=/root/flutter/bin/flutter
#   BRANCH=feature/initial-upload

PROJECT_DIR="${PROJECT_DIR:-/root/projects/video-marketplace-app}"
WEB_ROOT="${WEB_ROOT:-/var/www/gogomarket}"
FLUTTER_BIN="${FLUTTER_BIN:-/root/flutter/bin/flutter}"
BRANCH="${BRANCH:-}"

echo "== Deploy Flutter Web =="
echo "PROJECT_DIR=$PROJECT_DIR"
echo "WEB_ROOT=$WEB_ROOT"
echo "FLUTTER_BIN=$FLUTTER_BIN"

cd "$PROJECT_DIR"

if [ -n "$BRANCH" ]; then
  git checkout "$BRANCH"
fi

git status -sb || true
echo "Commit: $(git rev-parse HEAD)"

if [ ! -x "$FLUTTER_BIN" ]; then
  if command -v flutter >/dev/null 2>&1; then
    FLUTTER_BIN="$(command -v flutter)"
  else
    echo "ERROR: Flutter not found. Set FLUTTER_BIN or install flutter." >&2
    exit 1
  fi
fi

"$FLUTTER_BIN" pub get

# Web build fix:
# mobile_scanner declares a web plugin that conflicts with dart:html ImageCapture.
# Even if app code doesn't use QR scanning on web, Flutter's generated web plugin
# registrant can pull in the web implementation and break compilation.
#
# We patch the *pub-cache* copy of mobile_scanner just for the duration of the build
# (disable platforms.web in its pubspec.yaml), then restore it afterwards.
echo "== Patch mobile_scanner web plugin (temporary) =="
PKG_CONFIG=".dart_tool/package_config.json"
if [ -f "$PKG_CONFIG" ]; then
  MOBILE_SCANNER_DIR="$(
    python3 - <<'PY'
import json, pathlib, urllib.parse, sys
p = pathlib.Path(".dart_tool/package_config.json")
cfg = json.loads(p.read_text())
for pkg in cfg.get("packages", []):
    if pkg.get("name") == "mobile_scanner":
        uri = pkg.get("rootUri")
        # rootUri is usually "file:///..." or relative "file://"
        if uri.startswith("file:"):
            path = urllib.parse.urlparse(uri).path
            print(pathlib.Path(path).resolve())
        else:
            print((p.parent / uri).resolve())
        sys.exit(0)
sys.exit(1)
PY
  )" || MOBILE_SCANNER_DIR=""

  if [ -n "${MOBILE_SCANNER_DIR:-}" ] && [ -f "$MOBILE_SCANNER_DIR/pubspec.yaml" ]; then
    MS_PUB="$MOBILE_SCANNER_DIR/pubspec.yaml"
    MS_BAK="/tmp/mobile_scanner_pubspec.yaml.bak.$$"
    cp "$MS_PUB" "$MS_BAK"
    python3 - <<PY
from pathlib import Path

p = Path("$MS_PUB")
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

    restore_mobile_scanner_pubspec() {
      if [ -f "$MS_BAK" ]; then
        cp "$MS_BAK" "$MS_PUB" || true
        rm -f "$MS_BAK" || true
      fi
    }
    trap restore_mobile_scanner_pubspec EXIT

    echo "Patched: $MS_PUB"
  else
    echo "WARN: mobile_scanner pubspec not found; continuing without patch."
  fi
else
  echo "WARN: $PKG_CONFIG not found; skipping mobile_scanner patch."
fi

echo "== Build web =="
"$FLUTTER_BIN" build web --release

sudo mkdir -p "$WEB_ROOT"
sudo rsync -av --delete build/web/ "$WEB_ROOT/"
echo "$(git rev-parse HEAD)" | sudo tee "$WEB_ROOT/.last_build_id" >/dev/null
sudo systemctl reload nginx || true

echo "== Done =="
if [ -f "$WEB_ROOT/version.json" ]; then
  sudo cat "$WEB_ROOT/version.json" || true
fi
echo "DEPLOYED_COMMIT=$(sudo cat "$WEB_ROOT/.last_build_id" 2>/dev/null || true)"

