# DEPLOYMENT (Web, production)

## TL;DR

- Прод Web: `https://165.232.81.31`
- Деплой Web делается **автоматически** через GitHub Actions по SSH.
- Триггер: push в ветку **`cursor/what-has-been-done-5e03`**.

Актуальный контекст и ссылки: `docs/HANDOFF.md`.

## Как устроен деплой

- Workflow: `.github/workflows/deploy_web.yml` (**Deploy Flutter Web (SSH)**)
  - `Build Flutter Web (preflight)`:
    - ставит Flutter (сейчас: `3.38.5`)
    - запускает guard “no const + .tr”
    - собирает Web через `scripts/build_web.sh`
  - `deploy`:
    - подключается по SSH
    - делает чистый checkout ветки
    - запускает `scripts/deploy_web.sh` на сервере

На сервере деплой:
- собирает `flutter build web --release`
- синхронизирует файлы в web root (Nginx)
- пишет `.last_build_id` (SHA коммита)

## Проверка что задеплоилось

### 1) Быстро узнать SHA на проде

```bash
curl -kfsS https://165.232.81.31/.last_build_id | tr -d '\r\n'
```

### 2) Smoke test (как в CI/операционно)

```bash
bash scripts/smoke_test_prod.sh
```

## Частые проблемы (и что делать)

### “Web не собирается”: `const + .tr`

Симптом: `flutter build web --release` падает, когда `.tr` используется внутри `const`.

Решение: убрать `const` вокруг виджета, где есть `.tr` / `.trParams`.

### “На сервере конфликт при pull”

В workflow уже принудительно делается:
- `git reset --hard`
- `git clean -fd`
- `git checkout -B ... origin/...`

Если вы меняли server-side руками — откатите это, сервер должен быть “тупым исполнителем” деплоя.

## Секреты и настройки (GitHub)

Workflow использует GitHub Secrets (точные названия — см. `.github/workflows/deploy_web.yml`), включая:
- `DEPLOY_HOST`, `DEPLOY_USER`
- `DEPLOY_PROJECT_DIR`, `DEPLOY_WEB_ROOT`, `DEPLOY_FLUTTER_BIN`
- `DEPLOY_SSH_KEY_B64` (предпочтительно) или `DEPLOY_SSH_KEY`

## Feature flags / включение фич без кода (DART_DEFINES)

Можно включать фичи через build-time defines без правок кода:

- В GitHub → **Settings → Secrets and variables → Actions → Variables**
- Создать Variable: **`DART_DEFINES`**
- Значение (пример):

```text
ENABLE_MEDIA_UPLOAD=true ENABLE_PRODUCT_REVIEWS=true
```

Этот параметр будет прокинут в:
- CI preflight web build
- server-side build при деплое

## См. также

- `docs/HANDOFF.md` — текущее состояние, урлы, грабли, последний деплой
- `docs/DEPLOY_AUTOMATION_GITHUB_ACTIONS.md` — детали настройки автодеплоя
- `docs/BACKEND_TASKS.md` — список задач для backend (upload/reviews)

