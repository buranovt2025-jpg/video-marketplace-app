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
#   DART_DEFINES="KEY=VALUE KEY2=VALUE2" (optional)
#   WEB_RENDERER=auto|html|canvaskit (default: html)

FLUTTER_BIN="${FLUTTER_BIN:-}"
PWA_STRATEGY="${PWA_STRATEGY:-none}"
DART_DEFINES="${DART_DEFINES:-}"
WEB_RENDERER="${WEB_RENDERER:-html}"

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
echo "DART_DEFINES=$DART_DEFINES"
echo "WEB_RENDERER=$WEB_RENDERER"

echo "== Flutter clean/pub get =="
"$FLUTTER_BIN" clean
"$FLUTTER_BIN" pub get

echo "== flutter build web --release =="
extra_defines=()
if [ -n "${DART_DEFINES}" ]; then
  # Accept space-separated KEY=VALUE pairs.
  for pair in ${DART_DEFINES}; do
    extra_defines+=( "--dart-define=${pair}" )
  done
fi

# Renderer selection (helps startup performance / Speed Index).
#
# Flutter may remove/rename `--web-renderer`, so we rely on a dart-define
# that works on modern toolchains.
case "$WEB_RENDERER" in
  auto)
    ;;
  html)
    if [[ " $DART_DEFINES " != *" FLUTTER_WEB_USE_SKIA="* ]]; then
      extra_defines+=( "--dart-define=FLUTTER_WEB_USE_SKIA=false" )
    fi
    ;;
  canvaskit)
    if [[ " $DART_DEFINES " != *" FLUTTER_WEB_USE_SKIA="* ]]; then
      extra_defines+=( "--dart-define=FLUTTER_WEB_USE_SKIA=true" )
    fi
    ;;
  *)
    echo "ERROR: WEB_RENDERER must be auto|html|canvaskit (got: $WEB_RENDERER)" >&2
    exit 1
    ;;
esac

"$FLUTTER_BIN" build web --release --no-source-maps --tree-shake-icons --pwa-strategy="$PWA_STRATEGY" "${extra_defines[@]}"

echo "== Build OK =="

