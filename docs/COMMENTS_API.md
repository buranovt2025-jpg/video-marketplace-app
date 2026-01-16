# Comments API (contract / plan)

На фронте “кнопка комментариев” сейчас сделана как аккуратный `Coming soon`, потому что в текущем API нет endpoints для комментариев.

Ниже — минимальный контракт, который нужен, чтобы включить реальные комментарии.

## Модель комментария (пример)

- `id`: string | int
- `content_id`: string | int
- `author_id`: string | int
- `author_name`: string
- `author_avatar_url`: string?
- `text`: string
- `created_at`: ISO string

## Endpoints

### Получить список комментариев

`GET /api/content/{content_id}/comments?limit=50&cursor=...`

Response:
- `items`: Comment[]
- `next_cursor`: string?

### Добавить комментарий

`POST /api/content/{content_id}/comments`

Body:
- `text`: string

Response:
- `comment`: Comment

### Удалить комментарий (автор/админ)

`DELETE /api/comments/{comment_id}`

## Счётчики

Чтобы UI был быстрым:
- в `GET /api/content/reels` отдавать `comments_count`
- инкрементировать/декрементировать на backend при create/delete

## Что нужно поменять во Flutter (когда API появится)

- Экран/шит комментариев:
  - загрузка с пагинацией
  - отправка текста
  - обработка ошибок/empty state
- Опционально: optimistic UI (добавили в список сразу, потом синк)

