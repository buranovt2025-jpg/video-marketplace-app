# Тестирование Gogomarket.uz - TODO

## Рекомендации из веб-анализа

### Unit Tests (Юнит-тесты)
- Тестирование отдельных функций и методов
- MarketplaceController: getComments, postComment, toggleLike, loadContent
- ApiService: все HTTP методы
- Утилиты: форматирование дат, валидация данных

### Widget Tests (Виджет-тесты)
- Тестирование UI компонентов
- Comments bottom sheet
- Product cards
- Video player controls
- Navigation между экранами

### Integration Tests (Интеграционные тесты)
- Полный flow регистрации/входа
- Покупка товара от просмотра до оплаты
- Создание контента (reels/stories)
- Переключение ролей

### Цель покрытия: 60%

## Приоритет
Тесты добавляются ПОСЛЕ завершения основного функционала:
1. Поиск товаров
2. Фильтры по категориям
3. SSL сертификат
4. Push-уведомления
5. **Затем тесты**

## Команды для запуска тестов
```bash
# Unit tests
flutter test

# Widget tests
flutter test --tags widget

# Integration tests
flutter test integration_test/

# Coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

Дата создания: 2024-12-29
