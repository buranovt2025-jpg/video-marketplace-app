# Handoff / Continuation Notes (for next chat)

## Current state (as of last successful deploy)

- **Repo**: `/workspace` (Flutter app)
- **Active branch**: `cursor/what-has-been-done-5e03`
- **Deploy workflow**: `.github/workflows/deploy_web.yml` (name: **Deploy Flutter Web (SSH)**)
- **Prod Web**: `https://165.232.81.31`
- **Prod API**: `https://app-owphiuvd.fly.dev`
- **Last deployed web commit**: `8bd63ebd243d06bc66a800fcd7e9543f4f5dc170` (from `/.last_build_id`)
- **Smoke test**: `bash scripts/smoke_test_prod.sh` (passed after the deploy above)

## Feature flags (build-time)

Feature flags are controlled via `--dart-define` and can be passed from CI/server via `DART_DEFINES`:
- `ENABLE_MEDIA_UPLOAD=true` — enables upload mode in Create Reel/Story (requires backend `/api/uploads`)
- `ENABLE_PRODUCT_REVIEWS=true` — enables product reviews UI (requires backend reviews endpoints)

Docs:
- `docs/DEPLOYMENT.md` (how to set `DART_DEFINES`)
- `docs/BACKEND_TASKS.md`, `docs/MEDIA_UPLOAD.md`, `docs/REVIEWS_API.md`

## What we changed recently

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
bash scripts/smoke_test_prod.sh
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

