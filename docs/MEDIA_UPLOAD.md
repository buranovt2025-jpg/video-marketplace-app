# Media upload (contract / plan)

Сейчас `Reels/Stories` создаются через `video_url` / `image_url` строками (см. `ApiService.createContent()`).
Чтобы “по‑настоящему” работать как маркетплейс, нужен **upload → storage → URL**.

## Цели

- Пользователь выбирает файл (видео/фото) в приложении.
- Файл загружается в storage (S3/DO Spaces/Cloudflare R2).
- Backend возвращает стабильный публичный URL (и, желательно, thumbnail).
- Flutter Web playback работает стабильно (без `MEDIA_ERR_SRC_NOT_SUPPORTED`).

## Требования к видео URL (Web playback)

Чтобы mp4 стабильно проигрывался в браузере (через `video_player_web`), storage/CDN должен:
- отдавать корректный `Content-Type: video/mp4` (или `video/webm` и т.п.)
- поддерживать `Accept-Ranges: bytes` (чтобы браузер мог делать range requests)
- не блокировать hotlink (CORS и доступ по HTTPS)
- иметь доступный `Content-Length`

## Рекомендуемый подход: presigned upload (S3‑style)

### 1) Создать upload‑сессию

`POST /api/uploads`

Body:
- `kind`: `"reel_video" | "story_video" | "story_image" | "product_image"`
- `filename`: string
- `content_type`: string (например `video/mp4`)
- `size_bytes`: number

Response (пример):
- `upload_url`: string (presigned PUT)
- `file_url`: string (публичный URL для воспроизведения)
- `headers`: map (например, требуемые заголовки)
- `expires_in`: number

### 2) Клиент загружает файл напрямую в storage

`PUT upload_url` (с `Content-Type`)

### 3) Клиент создаёт контент в backend

Для рилса:
- `POST /api/content`
- `content_type: "reel"`
- `video_url: file_url`
- `thumbnail_url` (опционально, если backend генерирует)
- `product_id` (опционально)

## Thumbnail / poster (важно для UX)

Минимум:
- backend хранит `thumbnail_url` рядом с `video_url`

Хорошо:
- генерировать thumbnail server-side (ffmpeg) при загрузке
- хранить размеры/длительность/ratio (для UI и валидации)

## Что нужно поменять во Flutter (когда API появится)

- Добавить выбор файла в `CreateReelScreen` / `CreateStoryScreen`
- В `ApiService` добавить методы:
  - `createUploadSession(...)`
  - `uploadToPresignedUrl(...)`
- После успешного upload вызывать `createContent(videoUrl: fileUrl, ...)`

