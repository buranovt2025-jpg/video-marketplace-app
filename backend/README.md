# Backend module (FastAPI) — uploads + product reviews

В этом репозитории основное приложение — Flutter.  
Этот каталог добавляет **готовую реализацию backend endpoints** для:

- `POST /api/uploads` — presigned S3‑style upload (подходит для DigitalOcean Spaces)
- `GET/POST /api/products/{id}/reviews` — отзывы и рейтинг товара

> Это “встраиваемый” модуль. Его можно:
> - запустить отдельно (локально/в контейнере) для тестов,
> - или перенести/интегрировать в ваш существующий backend.

## Быстрый старт (локально, без Spaces)

Требования: Python 3.11+

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r backend/requirements.txt
uvicorn backend.app.main:app --reload --port 8000
```

Проверка:

```bash
curl -sS http://127.0.0.1:8000/healthz
```

## Presigned uploads (Spaces/S3)

Нужно задать переменные окружения (пример см. `backend/.env.example`):

- `S3_ENDPOINT` (например `https://fra1.digitaloceanspaces.com`)
- `S3_REGION` (например `fra1`)
- `S3_BUCKET`
- `S3_ACCESS_KEY_ID`
- `S3_SECRET_ACCESS_KEY`
- `S3_PUBLIC_BASE_URL` (например `https://<bucket>.<region>.digitaloceanspaces.com`)

Тогда `POST /api/uploads` будет возвращать:
- `upload_url` (presigned PUT)
- `file_url` (публичный URL)
- `headers` (включая `Content-Type`)

## Reviews

Хранятся в SQLite (файл `backend/app/app.db`) по умолчанию.  
При интеграции в ваш backend — замените хранилище на вашу БД.

## Интеграция с Flutter фичефлагами

Когда backend endpoints доступны в проде, включайте UI на web через GitHub Variable `DART_DEFINES`:

```text
ENABLE_MEDIA_UPLOAD=true ENABLE_PRODUCT_REVIEWS=true
```

См. `docs/DEPLOYMENT.md` и `docs/BACKEND_TASKS.md`.

