# Server patch notes: `/opt/gogomarket` (prod API)

Этот файл фиксирует изменения, сделанные **на сервере** в существующем backend’е `/opt/gogomarket`.

Цель: разблокировать Flutter-фичи **uploads** и **product reviews** без поднятия отдельного backend на 8010.

## Что было сделано

- **Backend**: `gogomarket.service` (systemd) запускает:
  - `/opt/gogomarket/venv/bin/uvicorn main:app`
- Добавлены endpoints (внутри существующего FastAPI app):
  - `POST /api/uploads` (JWT auth required, S3/Spaces presigned PUT)
  - `GET /api/products/{id}/reviews`
  - `POST /api/products/{id}/reviews`
- Nginx уже проксирует `/api` и `/ws` на `127.0.0.1:8000` по HTTPS.

## Где лежат файлы

- `feature_api.py` (добавленный модуль): `/opt/gogomarket/feature_api.py`
- Подключение в приложение: `/opt/gogomarket/main.py` (добавлен `include_router(...)` под `try/except`)

## Переменные окружения

Используются переменные из `gogomarket.service` + общий env-файл:

- JWT:
  - `JWT_SECRET` (обязателен)
  - `JWT_ALG` (опционально, default `HS256`)
- DB:
  - `DATABASE_URL` (обязателен; reviews создают таблицу `product_reviews`)
- S3/Spaces (для `/api/uploads`):
  - `S3_ENDPOINT`
  - `S3_REGION`
  - `S3_BUCKET`
  - `S3_ACCESS_KEY_ID`
  - `S3_SECRET_ACCESS_KEY`
  - `S3_PUBLIC_BASE_URL`
  - `UPLOAD_URL_TTL_SECONDS` (опционально, default `900`)

На сервере env хранится в `/etc/gogomarket-backend.env`.

## Безопасность: закрыть внешний порт 8000

Чтобы backend не торчал наружу, добавлен systemd drop-in:

- `/etc/systemd/system/gogomarket.service.d/20-bind-local.conf`

Содержание (пример):

```ini
[Service]
ExecStart=
ExecStart=/opt/gogomarket/venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000
```

Применить:

```bash
sudo systemctl daemon-reload
sudo systemctl restart gogomarket
sudo ss -ltnp | grep -E ':8000\\b'
```

Ожидаемо: `127.0.0.1:8000`, не `0.0.0.0:8000`.

## Проверка

Локально на сервере:

```bash
curl -fsS http://127.0.0.1:8000/healthz
curl -sS -o /dev/null -w "reviews_http=%{http_code}\\n" http://127.0.0.1:8000/api/products/1/reviews
```

Через HTTPS домен:

```bash
curl -kfsS https://165.232.81.31/healthz
curl -kfsS -o /dev/null -w "reviews_http=%{http_code}\\n" https://165.232.81.31/api/products/1/reviews
```

Smoke + acceptance (из репозитория на сервере):

```bash
cd /home/deploy/projects/video-marketplace-app
API_INSECURE=1 FEATURE_API_INSECURE=1 RUN_BACKEND_CHECKS=1 WEB_URL=https://165.232.81.31 API_URL=https://165.232.81.31 bash scripts/smoke_test_prod.sh
```

## Откат (rollback)

Если нужно откатить изменения:

1) Удалить/отключить роутер:
   - откатить изменения в `/opt/gogomarket/main.py` (убрать подключение `feature_api`)
   - удалить `/opt/gogomarket/feature_api.py` (или переименовать)
2) Перезапустить сервис:

```bash
sudo systemctl restart gogomarket
```

3) (опционально) вернуть прослушивание `0.0.0.0:8000`:
   - удалить drop-in `/etc/systemd/system/gogomarket.service.d/20-bind-local.conf`
   - `sudo systemctl daemon-reload && sudo systemctl restart gogomarket`

