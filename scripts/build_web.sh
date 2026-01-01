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
#   (no other options)

FLUTTER_BIN="${FLUTTER_BIN:-}"
PWA_STRATEGY="${PWA_STRATEGY:-none}"

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

echo "== Build Flutter Web =="
resolve_flutter
echo "FLUTTER_BIN=$FLUTTER_BIN"
echo "PWA_STRATEGY=$PWA_STRATEGY"

echo "== Flutter clean/pub get =="
"$FLUTTER_BIN" clean
"$FLUTTER_BIN" pub get

echo "== flutter build web --release =="
"$FLUTTER_BIN" build web --release --pwa-strategy="$PWA_STRATEGY"

echo "== Build OK =="

