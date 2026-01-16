# Payments (plan)

Сейчас MVP использует **COD (cash on delivery)** в `CheckoutScreen`.
Онлайн‑оплата — отдельная итерация, потому что затрагивает backend, статусы заказа и UX ошибок.

## Что нужно в модели заказа (backend)

Рекомендуемые поля:
- `payment_method`: `"cod" | "online"`
- `payment_provider`: `"payme" | "click" | "stripe" | ...` (nullable)
- `payment_status`: `"unpaid" | "pending" | "paid" | "failed" | "refunded"`
- `payment_transaction_id`: string? (nullable)
- `paid_at`: ISO? (nullable)

## Минимальный поток online‑оплаты

1) Клиент создаёт заказ в статусе `created` + `payment_status=pending`
2) Клиент получает `payment_intent`/`checkout_url` от backend
3) Клиент завершает оплату (SDK/redirect)
4) Backend подтверждает оплату (webhook) → `payment_status=paid`
5) UI обновляется пушем/поллингом

## UX требования

- Нельзя “молча” терять оплату: нужны явные экраны `pending/failed/success`.
- Повторная попытка оплаты должна быть возможна (если заказ ещё актуален).

## Что меняется во Flutter

- В `CheckoutScreen` добавить выбор:
  - COD (как сейчас)
  - Online (скрыто фичефлагом до готовности backend)
- Добавить экран статуса оплаты для заказа.

