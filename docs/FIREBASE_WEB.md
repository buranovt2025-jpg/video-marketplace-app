## Firebase на Web: почему выключено по умолчанию

В проекте используются Firebase пакеты (auth/storage/firestore) для “TikTok‑части” приложения и исторически они вызывали ошибки на Web, если нет web‑конфига.

### Что нужно для Firebase Web

Нужен файл `lib/firebase_options.dart`, который генерируется командой:

```bash
flutterfire configure
```

Инициализация должна выглядеть так:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### Текущее поведение

В `lib/main.dart` Firebase на Web **пропускается**, если не задан флаг:
- `--dart-define=ENABLE_FIREBASE_WEB=true`

Это сделано, чтобы web‑прод (FastAPI backend) не падал и не спамил консолью, пока web‑конфиг Firebase не подключён.

### Как включить

1) Сгенерировать `lib/firebase_options.dart` через `flutterfire configure`
2) Пересобрать Web:

```bash
flutter build web --release --dart-define=ENABLE_FIREBASE_WEB=true
```

