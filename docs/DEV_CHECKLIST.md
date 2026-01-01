# DEV_CHECKLIST (GoGoMarket)

Этот файл — короткий чек‑лист для ежедневной разработки и безопасных релизов.

## Предпосылки

- **Flutter toolchain**: держите в синхронизации с CI/сервером (сейчас в CI: **Flutter 3.38.5**).
- **Ветка автодеплоя Web**: `cursor/what-has-been-done-5e03` (см. `docs/HANDOFF.md`).

## Ежедневный цикл (локально)

```bash
git status
dart format .
flutter analyze
flutter test
```

## Зависимости

Проверить доступные обновления:

```bash
flutter pub outdated
```

Обновлять зависимости аккуратно:

```bash
flutter pub upgrade
# или, если понимаете последствия:
# flutter pub upgrade --major-versions
```

После изменений зависимостей обязательно:

```bash
flutter clean
flutter pub get
flutter test
flutter build web --release
```

## Web-специфика (важно)

- **Запрещено**: использовать `.tr`/`.trParams` внутри `const`‑виджетов — Flutter Web не соберётся.
  - Пример плохо: `const Text('key'.tr)`
  - Пример хорошо: `Text('key'.tr)` (без `const`)

CI содержит guard: `python3 scripts/check_no_const_tr.py`.

## Быстрая проверка сборки Web

```bash
flutter clean
flutter pub get
flutter build web --release
```

## Что проверять перед отправкой изменений

- Не сломали ли навигацию по ролям (buyer/seller/courier/admin/guest)
- Не появились ли “серые/пустые” экраны из-за null/типов данных
- Нет ли новых hardcoded строк (особенно RU) — добавляйте ключи в `lib/l10n/app_translations.dart`

