# 🔧 Firebase Storage - Конфигурация для приложения

**Проект**: video-marketplace-app-53a6d  
**Дата**: 23 декабря 2025

---

## 📦 Storage Bucket URL

```
gs://video-marketplace-app-53a6d.firebasestorage.app
```

**Для использования в коде:**
```dart
// Flutter/Dart
final storageRef = FirebaseStorage.instance.ref();

// Или с явным указанием bucket
final storage = FirebaseStorage.instanceFor(
  bucket: 'gs://video-marketplace-app-53a6d.firebasestorage.app'
);
```

---

## 🌍 Регион

- **Location**: ASIA-SOUTH2 (Delhi, India)
- **Storage Class**: Regional
- **Access Frequency**: Standard

**Примечание**: Регион совпадает с Firestore Database для оптимальной производительности.

---

## 🔐 Правила безопасности

**Текущие правила** (опубликованы 23.12.2025):

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Описание**:
- ✅ Чтение разрешено только авторизованным пользователям
- ✅ Запись разрешена только авторизованным пользователям
- ❌ Неавторизованные пользователи не имеют доступа

---

## 📝 Примеры использования

### Загрузка файла

```dart
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

Future<String> uploadFile(File file, String path) async {
  try {
    // Создаем ссылку на файл
    final storageRef = FirebaseStorage.instance.ref().child(path);
    
    // Загружаем файл
    final uploadTask = await storageRef.putFile(file);
    
    // Получаем URL загруженного файла
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    
    return downloadUrl;
  } catch (e) {
    print('Ошибка загрузки файла: $e');
    rethrow;
  }
}

// Пример использования
final file = File('/path/to/video.mp4');
final url = await uploadFile(file, 'videos/user123/video1.mp4');
print('Файл загружен: $url');
```

### Скачивание файла

```dart
Future<String> getDownloadUrl(String path) async {
  try {
    final storageRef = FirebaseStorage.instance.ref().child(path);
    final url = await storageRef.getDownloadURL();
    return url;
  } catch (e) {
    print('Ошибка получения URL: $e');
    rethrow;
  }
}

// Пример использования
final url = await getDownloadUrl('videos/user123/video1.mp4');
print('URL для скачивания: $url');
```

### Удаление файла

```dart
Future<void> deleteFile(String path) async {
  try {
    final storageRef = FirebaseStorage.instance.ref().child(path);
    await storageRef.delete();
    print('Файл удален: $path');
  } catch (e) {
    print('Ошибка удаления файла: $e');
    rethrow;
  }
}

// Пример использования
await deleteFile('videos/user123/video1.mp4');
```

### Получение метаданных файла

```dart
Future<FullMetadata> getFileMetadata(String path) async {
  try {
    final storageRef = FirebaseStorage.instance.ref().child(path);
    final metadata = await storageRef.getMetadata();
    
    print('Размер: ${metadata.size} bytes');
    print('Тип: ${metadata.contentType}');
    print('Создан: ${metadata.timeCreated}');
    
    return metadata;
  } catch (e) {
    print('Ошибка получения метаданных: $e');
    rethrow;
  }
}
```

---

## 🎯 Рекомендуемая структура папок

```
gs://video-marketplace-app-53a6d.firebasestorage.app/
├── videos/
│   ├── {userId}/
│   │   ├── {videoId}.mp4
│   │   └── thumbnails/
│   │       └── {videoId}_thumb.jpg
├── images/
│   ├── profiles/
│   │   └── {userId}.jpg
│   └── covers/
│       └── {videoId}_cover.jpg
└── temp/
    └── {userId}/
        └── {tempFileId}
```

**Пример путей:**
- Видео: `videos/user123/video456.mp4`
- Превью: `videos/user123/thumbnails/video456_thumb.jpg`
- Аватар: `images/profiles/user123.jpg`
- Обложка: `images/covers/video456_cover.jpg`

---

## ⚠️ Важные замечания

1. **Аутентификация обязательна**: Все операции требуют авторизации пользователя через Firebase Authentication.

2. **Размер файлов**: Убедитесь, что размер загружаемых файлов не превышает лимиты Firebase Storage:
   - Free Spark Plan: 5 GB хранилища, 1 GB/день загрузки
   - Blaze Plan (Pay as you go): без ограничений

3. **Оптимизация**: Сжимайте видео и изображения перед загрузкой для экономии места и трафика.

4. **Безопасность**: Текущие правила разрешают любым авторизованным пользователям читать и записывать файлы. Рассмотрите возможность более детальной настройки:

```javascript
// Пример более строгих правил
match /videos/{userId}/{videoId} {
  // Только владелец может записывать
  allow write: if request.auth != null && request.auth.uid == userId;
  // Все авторизованные могут читать
  allow read: if request.auth != null;
}
```

5. **Мониторинг**: Регулярно проверяйте использование Storage в Firebase Console → Storage → Usage.

---

## 📊 Квоты и лимиты

### Free Spark Plan (текущий)
- **Хранилище**: 5 GB
- **Загрузка**: 1 GB/день
- **Скачивание**: 10 GB/день
- **Операции**: 50,000/день

### Blaze Plan (Pay as you go)
- **Хранилище**: $0.026/GB/месяц
- **Загрузка**: $0.12/GB
- **Скачивание**: $0.12/GB
- **Операции**: $0.05/10,000 операций

**Примечание**: У вас активен Free Trial с $300 кредитов на 91 день.

---

## 🔗 Полезные ссылки

- **Firebase Console**: https://console.firebase.google.com/project/video-marketplace-app-53a6d/storage
- **Storage Rules**: https://console.firebase.google.com/project/video-marketplace-app-53a6d/storage/rules
- **Документация**: https://firebase.google.com/docs/storage
- **Flutter Plugin**: https://pub.dev/packages/firebase_storage

---

**Конфигурация подготовлена**: 23 декабря 2025  
**Статус**: ✅ Storage готов к использованию
