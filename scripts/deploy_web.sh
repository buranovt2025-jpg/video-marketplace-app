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

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
    SUDO="sudo -n"
  else
    echo "ERROR: Need passwordless sudo (non-interactive) or run as root." >&2
    exit 1
  fi
fi

echo "== Build web =="
PROJECT_DIR="$PROJECT_DIR" FLUTTER_BIN="$FLUTTER_BIN" bash scripts/build_web.sh

echo "== Deploy web build to nginx root =="
$SUDO mkdir -p "$WEB_ROOT"
$SUDO rsync -av --delete build/web/ "$WEB_ROOT/"
echo "$(git rev-parse HEAD)" | $SUDO tee "$WEB_ROOT/.last_build_id" >/dev/null
$SUDO systemctl reload nginx || true

echo "== Done =="
if [ -f "$WEB_ROOT/version.json" ]; then
  $SUDO cat "$WEB_ROOT/version.json" || true
fi
echo "DEPLOYED_COMMIT=$($SUDO cat "$WEB_ROOT/.last_build_id" 2>/dev/null || true)"

