## Видео для Reels/Stories: как сделать “правильно”

Сейчас фронт умеет проигрывать видео по `video_url`, но **некоторые demo‑хосты** (например `sample-videos.com`) на Web периодически ломают воспроизведение (`MEDIA_ERR_SRC_NOT_SUPPORTED`) из‑за hotlink/заголовков/Range.

Мы добавили временную защиту: на Web для таких хостов включён fallback на рабочее демо‑видео.

### Важно: как отключить fallback (когда будут нормальные ссылки)

Сборка Web:

```bash
flutter build web --release --dart-define=ENABLE_VIDEO_FALLBACK=false
```

По умолчанию fallback включён: `ENABLE_VIDEO_FALLBACK=true`.

### Правильный вариант (рекомендовано)

1) **Хранить mp4 на своём storage**:
- DigitalOcean Spaces (S3‑совместимый)
- AWS S3
- Cloudflare R2
- Firebase Storage (если есть `firebase_options.dart` и включён Firebase Web)

2) **Требования к отдаче видео для Web**:
- `Content-Type: video/mp4` (или корректный для формата)
- `Accept-Ranges: bytes` (важно для перемотки/streaming)
- корректный `Content-Length`
- CORS:
  - `Access-Control-Allow-Origin: *` (или ваш домен)
  - при необходимости `Access-Control-Allow-Headers: Range`

3) **Backend должен сохранять и отдавать**:
- `video_url` (прямая ссылка на mp4/stream)
- `thumbnail_url` (прямая ссылка на картинку)

### Что сейчас есть во фронте
- Валидация, что `video_url` **похожа на реальную ссылку на видео** (не HTML/не main.dart.js).
- На Web: для “плохих” хостов (в блоклисте) можно включить/выключить fallback через `ENABLE_VIDEO_FALLBACK`.

