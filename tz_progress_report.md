# GoGoMarket — TZ Progress Report

Дата: **2025-12-30**  
Ветка: `cursor/what-has-been-done-5e03`  
Prod: `https://165.232.81.31/` (nginx static)  
API: `https://app-owphiuvd.fly.dev`

---

## 1) Контекст и что именно деплоится

- **Web**: Flutter Web собирается и выкладывается в `/var/www/gogomarket/`.
- **Проверка деплоя**: используется `/var/www/gogomarket/version.json` и `/var/www/gogomarket/.last_build_id`.
- **API**: запросы идут на внешний backend `app-owphiuvd.fly.dev`.

---

## 2) Инцидент: “Белый экран” на web

### 2.1 Симптом
- После успешного деплоя (HTTP 200, `main.dart.js` грузится) UI оставался пустым/белым.
- Иногда в центре отображался текст `165.232.81.31:50`.

### 2.2 Диагностика (что увидели)
- self‑signed SSL на `165.232.81.31` вызывает ошибку:
  - **Service Worker registration failed** (“SSL certificate error”).
- Браузер делал fallback на plain `<script>` (но это не гарантировало корректный запуск).
- Ошибки старта Flutter могли происходить “тихо” (white screen без понятного сообщения).

### 2.3 Принятое решение (прагматичный hotfix)
Так как исправление SSL сертификата на проде требует отдельной операции (Let’s Encrypt/DNS), сделали hotfix:
- **исключить влияние Service Worker/PWA** при self‑signed SSL;
- **сделать падения старта видимыми** (UI+логи).

### 2.4 Изменения во фронте (hotfix)

#### A) Усиление диагностики старта
- В `lib/main.dart` добавлены:
  - глобальные обработчики ошибок (`FlutterError.onError`, `PlatformDispatcher.instance.onError`);
  - логирование стадий старта;
  - fallback‑экран ошибки (чтобы вместо белого экрана видеть текст ошибки/stack).

#### B) Отключение Service Worker/PWA
- `web/index.html`: удалена регистрация `navigator.serviceWorker.register(...)`, принудительно грузим `main.dart.js` через plain `<script>`.
- `scripts/deploy_web.sh`: по умолчанию сборка запускается с `--pwa-strategy=none` (чтобы не генерировать/не использовать SW).

#### C) Firebase init без блокировки старта
- `Firebase.initializeApp()` выполняется в `try/catch`.
- На web без `firebase_options.dart` (flutterfire configure) инициализация может падать — теперь это **логируется**, но **не останавливает** запуск приложения.

### 2.5 Результат после деплоя (со слов Devin)
- **Белый экран → чёрный экран с оранжевым loading spinner** (рендер Flutter пошёл, “silent fail” уменьшился).

---

## 3) Новый блокер: 401 Unauthorized на `/api/auth/me`

### 3.1 Симптом
- Приложение стартует, но “висит” на загрузке.
- В консоли: `GET https://app-owphiuvd.fly.dev/api/auth/me` → **401**.

### 3.2 Проверка backend (быстрая)
- `https://app-owphiuvd.fly.dev/healthz` → **200**
- `https://app-owphiuvd.fly.dev/api/auth/me` без токена → **401** (нормально для защищённого эндпоинта)

### 3.3 Причина зависания во фронте
- Роутинг опирался на `ApiService.isLoggedIn` (наличие токена), а при 401 токен очищался и `currentUser` становился `null`, из‑за чего UI мог оставаться на бесконечном спиннере.

### 3.4 Фикс во фронте
- В `AppRouter` добавлена проверка: если токен очищен (`!ApiService.isLoggedIn`) — показываем **экран логина**, а не бесконечный `CircularProgressIndicator`.

---

## 4) Деплой (на сервере)

```bash
cd /root/projects/video-marketplace-app
git fetch origin
git checkout cursor/what-has-been-done-5e03
git pull origin cursor/what-has-been-done-5e03
bash scripts/deploy_web.sh
```

---

## 5) План проверки после деплоя

- **Smoke**:
  - открыть `https://165.232.81.31/` → приложение не белое;
  - если токен невалиден → должен появиться **логин**, а не вечный loader.
- **Auth flow**:
  - залогиниться → убедиться, что токен сохраняется;
  - убедиться, что `/api/auth/me` больше не 401 (по поведению UI / вкладке Network).

---

## 6) Открытые вопросы / риски

- **SSL**: self‑signed остаётся и будет мешать PWA/SW. Для “настоящего” прода нужен нормальный сертификат (Let’s Encrypt + домен).
- **Firebase web**: без `firebase_options.dart` Firebase web‑фичи работать не будут. Сейчас стратегия: app не падает, но Firebase‑части могут быть недоступны.
- **Причина 401**: нужно понять, почему токен невалиден:
  - протух (exp) / неверный секрет на backend / сменили конфиг;
  - фронт хранит старый токен, который backend больше не принимает.
