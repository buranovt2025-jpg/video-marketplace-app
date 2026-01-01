#!/usr/bin/env bash
set -euo pipefail

# Smoke tests for GoGoMarket production:
# - Web static (nginx) on 165.232.81.31
# - Backend API on app-owphiuvd.fly.dev
#
# Usage:
#   bash scripts/smoke_test_prod.sh
#
# Optional env:
#   WEB_URL=https://165.232.81.31
#   API_URL=https://app-owphiuvd.fly.dev
#   API_INSECURE=0|1 (default: 0) - set to 1 for self-signed TLS on API_URL
#   SMOKE_EMAIL=buyer@demo.com
#   SMOKE_PASSWORD=demo123
#   RUN_BACKEND_CHECKS=0|1 (default: 0)
#
# Notes:
# - WEB_URL uses self-signed TLS, so we use curl -k for it.
# - This script does NOT print tokens/passwords.

WEB_URL="${WEB_URL:-https://165.232.81.31}"
API_URL="${API_URL:-https://app-owphiuvd.fly.dev}"
API_INSECURE="${API_INSECURE:-0}"
SMOKE_EMAIL="${SMOKE_EMAIL:-buyer@demo.com}"
SMOKE_PASSWORD="${SMOKE_PASSWORD:-demo123}"
RUN_BACKEND_CHECKS="${RUN_BACKEND_CHECKS:-0}"

curl_api() {
  if [ "$API_INSECURE" != "0" ]; then
    curl -k "$@"
  else
    curl "$@"
  fi
}

require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: missing dependency: $1" >&2
    exit 1
  }
}

require curl
require python3

echo "== GoGoMarket smoke test =="
echo "WEB_URL=$WEB_URL"
echo "API_URL=$API_URL"
echo ""

echo "== 1) Web static checks =="
curl -kfsS -o /dev/null "$WEB_URL/" && echo "OK: GET /"
curl -kfsS -o /dev/null "$WEB_URL/main.dart.js" && echo "OK: GET /main.dart.js"
curl -kfsS -o /dev/null "$WEB_URL/version.json" && echo "OK: GET /version.json"

LAST_BUILD_ID="$(curl -kfsS "$WEB_URL/.last_build_id" | tr -d '\r\n' || true)"
if [ -z "$LAST_BUILD_ID" ]; then
  echo "ERROR: WEB .last_build_id is empty/unavailable" >&2
  exit 1
fi
echo "OK: WEB .last_build_id=$LAST_BUILD_ID"

echo ""
echo "== 2) Backend health/auth checks =="
curl_api -fsS -o /dev/null "$API_URL/healthz" && echo "OK: API /healthz"

LOGIN_JSON="$(curl_api -fsS \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${SMOKE_EMAIL}\",\"password\":\"${SMOKE_PASSWORD}\"}" \
  "$API_URL/api/auth/login")"

TOKEN="$(printf '%s' "$LOGIN_JSON" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("access_token",""))')"
if [ -z "$TOKEN" ]; then
  echo "ERROR: login response has no access_token" >&2
  exit 1
fi
echo "OK: API login (token received)"

ME_HTTP="$(curl_api -sS -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" "$API_URL/api/auth/me")"
if [ "$ME_HTTP" != "200" ]; then
  echo "ERROR: GET /api/auth/me returned HTTP $ME_HTTP" >&2
  exit 1
fi
echo "OK: API /api/auth/me (200)"

ORDERS_HTTP="$(curl_api -sS -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" "$API_URL/api/orders")"
if [ "$ORDERS_HTTP" != "200" ]; then
  echo "ERROR: GET /api/orders returned HTTP $ORDERS_HTTP" >&2
  exit 1
fi
echo "OK: API /api/orders (200)"

echo ""
echo "== Smoke test PASSED =="

if [ "$RUN_BACKEND_CHECKS" != "0" ]; then
  echo ""
  echo "== 3) Backend feature checks (optional) =="
  bash scripts/backend_acceptance_checks.sh
fi

