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

