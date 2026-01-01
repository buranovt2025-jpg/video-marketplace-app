# Product reviews & rating (contract / plan)

Фронт готов держать “Отзывы” на карточке товара как отдельный bottom‑sheet (листинг + отправка).
Чтобы включить функцию полностью, нужен API на backend.

## Модель отзыва (пример)

- `id`: string | int
- `product_id`: string | int
- `author_id`: string | int
- `author_name`: string
- `author_avatar_url`: string?
- `rating`: int (1..5)
- `text`: string?
- `created_at`: ISO string

## Endpoints

### Получить отзывы по товару

`GET /api/products/{product_id}/reviews?limit=50&cursor=...`

Response:
- `items`: Review[]
- `next_cursor`: string?
- `summary`: { `avg_rating`: number, `count`: number } (опционально)

### Оставить отзыв

`POST /api/products/{product_id}/reviews`

Body:
- `rating`: int (1..5)
- `text`: string? (опционально)

Response:
- `review`: Review
- `summary`: { `avg_rating`: number, `count`: number } (опционально)

### Удалить отзыв (автор/админ)

`DELETE /api/reviews/{review_id}`

## Что желательно отдавать в product

Чтобы карточка товара показывала рейтинг без отдельного запроса:
- `rating_avg`
- `rating_count`

