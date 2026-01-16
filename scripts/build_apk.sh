#!/usr/bin/env bash
set -euo pipefail

# Build release APK.
#
# Usage:
#   bash scripts/build_apk.sh
#
# Optional env:
#   PROJECT_DIR=/root/projects/video-marketplace-app
#   FLUTTER_BIN=/root/flutter/bin/flutter
#   BRANCH=feature/initial-upload

PROJECT_DIR="${PROJECT_DIR:-/root/projects/video-marketplace-app}"
FLUTTER_BIN="${FLUTTER_BIN:-/root/flutter/bin/flutter}"
BRANCH="${BRANCH:-}"

echo "== Build APK =="
echo "PROJECT_DIR=$PROJECT_DIR"
echo "FLUTTER_BIN=$FLUTTER_BIN"

cd "$PROJECT_DIR"

if [ -n "$BRANCH" ]; then
  git checkout "$BRANCH"
fi

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
"$FLUTTER_BIN" build apk --release

echo "== Output =="
ls -la build/app/outputs/flutter-apk/ || true

