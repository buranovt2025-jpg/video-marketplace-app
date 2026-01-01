#!/usr/bin/env bash
set -euo pipefail

# Backend acceptance checks for upcoming features:
# - Presigned uploads (/api/uploads)
# - Product reviews (/api/products/{id}/reviews)
#
# Usage:
#   bash scripts/backend_acceptance_checks.sh
#
# Optional env:
#   API_URL=https://app-owphiuvd.fly.dev
#   FEATURE_API_URL=http://127.0.0.1:8010 (optional; overrides uploads/reviews base)
#   WEB_URL=https://165.232.81.31
#   SMOKE_EMAIL=buyer@demo.com
#   SMOKE_PASSWORD=demo123
#   PRODUCT_ID=1
#
# Notes:
# - This script does not upload real files (it validates endpoints and headers).
# - For presigned upload validation, it checks that /api/uploads responds and returns upload_url/file_url.

API_URL="${API_URL:-https://app-owphiuvd.fly.dev}"
FEATURE_API_URL="${FEATURE_API_URL:-$API_URL}"
WEB_URL="${WEB_URL:-https://165.232.81.31}"
SMOKE_EMAIL="${SMOKE_EMAIL:-buyer@demo.com}"
SMOKE_PASSWORD="${SMOKE_PASSWORD:-demo123}"
PRODUCT_ID="${PRODUCT_ID:-1}"

require() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing dependency: $1" >&2; exit 1; }
}

require curl
require python3

echo "== Backend acceptance checks =="
echo "API_URL=$API_URL"
echo "FEATURE_API_URL=$FEATURE_API_URL"
echo "WEB_URL=$WEB_URL"
echo "PRODUCT_ID=$PRODUCT_ID"
echo ""

echo "== 0) Auth =="
LOGIN_JSON="$(curl -fsS \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${SMOKE_EMAIL}\",\"password\":\"${SMOKE_PASSWORD}\"}" \
  "$API_URL/api/auth/login")"

TOKEN="$(printf '%s' "$LOGIN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("access_token",""))')"
if [ -z "$TOKEN" ]; then
  echo "ERROR: login response has no access_token" >&2
  exit 1
fi
echo "OK: login"

echo ""
echo "== 1) Reviews endpoints =="
REV_HTTP="$(curl -sS -o /dev/null -w "%{http_code}" "$FEATURE_API_URL/api/products/$PRODUCT_ID/reviews")"
if [ "$REV_HTTP" = "404" ] || [ "$REV_HTTP" = "405" ] || [ "$REV_HTTP" = "501" ]; then
  echo "WARN: reviews endpoint not available yet (HTTP $REV_HTTP)"
else
  echo "OK: GET /api/products/$PRODUCT_ID/reviews (HTTP $REV_HTTP)"
fi

CREATE_REV_HTTP="$(curl -sS -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"rating":5,"text":"smoke"}' \
  "$FEATURE_API_URL/api/products/$PRODUCT_ID/reviews")"
if [ "$CREATE_REV_HTTP" = "404" ] || [ "$CREATE_REV_HTTP" = "405" ] || [ "$CREATE_REV_HTTP" = "501" ]; then
  echo "WARN: create review endpoint not available yet (HTTP $CREATE_REV_HTTP)"
else
  echo "OK: POST /api/products/$PRODUCT_ID/reviews (HTTP $CREATE_REV_HTTP)"
fi

echo ""
echo "== 2) Upload endpoint =="
UPLOAD_JSON_HTTP="$(curl -sS -w "\n%{http_code}" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"kind":"reel_video","filename":"smoke.mp4","content_type":"video/mp4","size_bytes":1024}' \
  "$FEATURE_API_URL/api/uploads" || true)"

UPLOAD_HTTP="$(printf '%s' "$UPLOAD_JSON_HTTP" | tail -n 1)"
UPLOAD_BODY="$(printf '%s' "$UPLOAD_JSON_HTTP" | sed '$d')"

if [ "$UPLOAD_HTTP" = "404" ] || [ "$UPLOAD_HTTP" = "405" ] || [ "$UPLOAD_HTTP" = "501" ]; then
  echo "WARN: upload endpoint not available yet (HTTP $UPLOAD_HTTP)"
else
  echo "OK: POST /api/uploads (HTTP $UPLOAD_HTTP)"
  UPLOAD_URL="$(printf '%s' "$UPLOAD_BODY" | python3 -c 'import sys,json; print((json.load(sys.stdin) or {}).get("upload_url",""))' 2>/dev/null || true)"
  FILE_URL="$(printf '%s' "$UPLOAD_BODY" | python3 -c 'import sys,json; print((json.load(sys.stdin) or {}).get("file_url",""))' 2>/dev/null || true)"
  if [ -z "$UPLOAD_URL" ] || [ -z "$FILE_URL" ]; then
    echo "ERROR: /api/uploads did not return upload_url/file_url" >&2
    exit 1
  fi
  echo "OK: upload_url/file_url present"

  # Optional: check that public file_url responds to HEAD (may 404 until PUT is done).
  FILE_HEAD_HTTP="$(curl -sS -o /dev/null -w "%{http_code}" -I "$FILE_URL" || true)"
  echo "INFO: HEAD file_url HTTP $FILE_HEAD_HTTP (may be 404 until upload completes)"
fi

echo ""
echo "== Done =="

