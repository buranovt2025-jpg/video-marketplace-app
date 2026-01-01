# Backend tasks (required to unlock next features)

Этот документ — “готовые” задачи для backend‑разработчика (FastAPI), чтобы включить:
- **Upload медиа** для Reels/Stories/Images
- **Отзывы товара** (rating + текст)

После реализации мы включим фичи на Web через `DART_DEFINES` (см. ниже).

## 0) Ссылки на контракты

- Upload: `docs/MEDIA_UPLOAD.md`
- Reviews: `docs/REVIEWS_API.md`
- Comments (доп.): `docs/COMMENTS_API.md`
- Payments (план): `docs/PAYMENTS.md`

## 1) Upload медиа (presigned PUT)

### 1.1 API

**Endpoint:** `POST /api/uploads` (auth required)

Body:
- `kind`: `"reel_video" | "story_video" | "story_image" | "product_image"`
- `filename`: string
- `content_type`: string (например `video/mp4`, `image/jpeg`)
- `size_bytes`: number

Response:
- `upload_url`: string (presigned PUT)
- `file_url`: string (публичный URL для чтения/проигрывания)
- `headers`: map<string,string> (опционально, если signature требует доп. заголовков)
- `expires_in`: number

### 1.2 Storage требования (Web playback)

Для **mp4 на Web** нужно:
- `Content-Type: video/mp4`
- `Accept-Ranges: bytes`
- корректный `Content-Length`
- CORS разрешает `GET/HEAD` для origin прод‑web

### 1.3 Валидации/безопасность

- лимиты:
  - видео (reel/story): 50MB (или больше, но согласовать)
  - фото: 10MB (пример)
- whitelist content types
- rate limit на пользователя
- storage path должен включать `user_id` + `uuid`/timestamp

### 1.4 Acceptance criteria

- `POST /api/uploads` работает с JWT и возвращает валидные URL
- `curl -I file_url` показывает требуемые headers
- Flutter Web:
  - при `ENABLE_MEDIA_UPLOAD=true` можно выбрать файл и опубликовать reel/story
  - видео проигрывается без `MEDIA_ERR_SRC_NOT_SUPPORTED`

## 2) Отзывы товара (product reviews)

### 2.1 API

**GET** `GET /api/products/{product_id}/reviews?limit=50&cursor=...`

Response:
- `items`: Review[]
- `next_cursor`: string? (опционально)
- `summary`: `{ avg_rating: number, count: number }` (опционально)

**POST** `POST /api/products/{product_id}/reviews` (auth required)

Body:
- `rating`: int (1..5)
- `text`: string? (опционально)

Response:
- `review`: Review
- `summary` (опционально)

**DELETE** `DELETE /api/reviews/{review_id}` (author/admin)

### 2.2 Product агрегаты (рекомендуется)

Чтобы UI мог показывать рейтинг без доп. запроса, добавить в `product`:
- `rating_avg`
- `rating_count`

### 2.3 Acceptance criteria

- при `ENABLE_PRODUCT_REVIEWS=true`:
  - карточка товара открывает sheet “Отзывы”
  - список грузится
  - отправка отзыва работает и обновляет список
  - UI начинает показывать `rating_avg/rating_count` (в quick‑buy и в подписи товара в reels viewer), если эти поля отдаёт backend

## 3) Как включить фичи на проде (после backend)

В GitHub → Settings → Secrets and variables → Actions → Variables:

- `DART_DEFINES` =

`ENABLE_MEDIA_UPLOAD=true ENABLE_PRODUCT_REVIEWS=true`

Workflow и server deploy уже прокидывают `DART_DEFINES` в `flutter build web`.

## 4) Быстрая проверка после выката backend

После внедрения upload/reviews на backend можно прогнать проверки:

```bash
# базовый smoke (web + auth + orders)
bash scripts/smoke_test_prod.sh

# + проверки backend endpoints (upload/reviews)
RUN_BACKEND_CHECKS=1 bash scripts/smoke_test_prod.sh
```

