# Handoff / Continuation Notes (for next chat)

## Current state (as of last successful deploy)

- **Repo**: `/workspace` (Flutter app)
- **Active branch**: `cursor/what-has-been-done-5e03`
- **Deploy workflow**: `.github/workflows/deploy_web.yml` (name: **Deploy Flutter Web (SSH)**)
- **Prod Web**: `https://165.232.81.31`
- **Prod API**:
  - public API used by most checks: `https://app-owphiuvd.fly.dev`
  - server-local API (self-hosted, self-signed): `https://165.232.81.31` (nginx proxies `/api` to `127.0.0.1:8000`)
- **Last deployed web commit**: `6ed149d4712ef46b32cd221ddea0b80da76fd340` (from `/.last_build_id`)
- **Smoke test**:
  - default: `bash scripts/smoke_test_prod.sh` (passed)
  - self-hosted API: `API_INSECURE=1 FEATURE_API_INSECURE=1 RUN_BACKEND_CHECKS=1 WEB_URL=https://165.232.81.31 API_URL=https://165.232.81.31 bash scripts/smoke_test_prod.sh` (passed)

## Feature flags (build-time)

Feature flags are controlled via `--dart-define` and can be passed from CI/server via `DART_DEFINES`:
- `ENABLE_MEDIA_UPLOAD=true` — enables upload mode in Create Reel/Story (requires backend `/api/uploads`)
- `ENABLE_PRODUCT_REVIEWS=true` — enables product reviews UI (requires backend reviews endpoints)
- `API_BASE_URL=https://165.232.81.31` — points the app to the nginx-proxied API on the same host as web

Docs:
- `docs/DEPLOYMENT.md` (how to set `DART_DEFINES`)
- `docs/BACKEND_TASKS.md`, `docs/MEDIA_UPLOAD.md`, `docs/REVIEWS_API.md`

## Prod backend notes (important)

There is an existing backend on the server managed by systemd:
- `gogomarket.service` runs `/opt/gogomarket/venv/bin/uvicorn main:app`.

To unlock **uploads + reviews**, we integrated two endpoints into that backend (server-side):
- `POST /api/uploads`
- `GET/POST /api/products/{id}/reviews`

And we hardened exposure:
- `gogomarket.service` now binds to `127.0.0.1:8000` (systemd drop-in).
- Nginx proxies `/api` + `/ws` over HTTPS.

Details / rollback steps: `docs/SERVER_GOGOMARKET_PATCH.md`.

## What we changed recently

### Web perf (Lighthouse)
- `web/index.html`
  - Added lightweight HTML splash screen (improved FCP/LCP and perceived load).
  - Preload `main.dart.js`, remove splash on `flutter-first-frame`.
- `scripts/build_web.sh`
  - Added `--no-source-maps` + `--tree-shake-icons`.
  - Added renderer switch via env `WEB_RENDERER` (default: `html`) + `FLUTTER_WEB_USE_SKIA` guidance.
- Result: FCP/LCP improved; next focus is Speed Index (startup + caching).

### Buyer UX: simplify bottom navigation
- `lib/views/screens/marketplace_home_screen.dart`
  - Buyer/Guest: replaced bottom “Search” tab with “Shorts/Reels”.
  - Buyer/Guest: removed “Orders” from bottom nav; orders entry moved into Profile.
  - Profile: buyer stats now show Orders/Favorites/Cart; profile primary CTA opens Orders.

### Chat stability / UX
- `lib/views/screens/chat/chat_screen.dart`
  - Added timeout + error state (Retry + pull-to-refresh + refresh button).
  - Added polling (periodic refresh) with merge/dedup logic.
  - Prevents “infinite spinner” feel when API is slow/unavailable.
- `lib/controllers/marketplace_controller.dart`
  - `getChatMessages(userId, {throwOnError})` to let UI distinguish “empty chat” vs “load failed”.
- Call sites updated to avoid `dynamic` `userId` issues:
  - `lib/views/screens/buyer/order_tracking_screen.dart`
  - `lib/views/screens/buyer/product_detail_screen.dart`
  - `lib/views/screens/courier/courier_order_detail_screen.dart`

### Localization cleanup
- Removed Cyrillic hardcoded strings from `lib/views/screens/**` where touched.
- Added missing keys to `lib/l10n/app_translations.dart` for RU/UZ/EN.

## Deployment notes (important)

### How deploy works
- A push to **`cursor/what-has-been-done-5e03`** triggers **Deploy Flutter Web (SSH)**.
- The server runs `scripts/deploy_web.sh` which:
  - runs `flutter build web --release`
  - rsyncs to nginx web root
  - writes `.last_build_id`

### Typical deploy failure we fixed
Flutter web compilation fails if you use `.tr` inside **const widgets**:
- Bad: `const Text('key'.tr)` / `const PopupMenuItem(child: Text('key'.tr))` / `return const Center(child: Text('key'.tr))`
- Fix: remove `const` on those widgets.

We fixed remaining offenders and deployed by committing:
- `fix(web): unblock build by removing const .tr widgets` (commit `5b2f12c`)

## Quick commands (local)

### Check prod deployed commit
```bash
curl -kfsS https://165.232.81.31/.last_build_id | tr -d '\r\n'
```

### Run prod smoke test
```bash
API_INSECURE=1 FEATURE_API_INSECURE=1 RUN_BACKEND_CHECKS=1 WEB_URL=https://165.232.81.31 API_URL=https://165.232.81.31 bash scripts/smoke_test_prod.sh
```

### See commits not on prod (replace HASH with current .last_build_id)
```bash
git log --oneline HASH..HEAD
```

## If starting a new chat with the agent
Give the agent:
- This file path: `docs/HANDOFF.md`
- The target branch: `cursor/what-has-been-done-5e03`
- What you want next (e.g., chat improvements, localization audit, new feature, etc.)

