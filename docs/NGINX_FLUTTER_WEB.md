## Nginx для Flutter Web (кэш + сжатие) — шаблон

Ниже — безопасный базовый конфиг, который обычно улучшает Lighthouse **Speed Index / TTFB** за счёт:

- **gzip** с корректными `Content-Type`;
- **кэширования статики** (картинки/шрифты/wasm), но **без** агрессивного кэша для `index.html`;
- правильных заголовков, чтобы браузер мог **реиспользовать** ресурсы между заходами.

> Примечание: у Flutter Web `main.dart.js` обычно **не имеет хэша в имени**, поэтому ему нельзя ставить “вечный” кэш. Иначе пользователи могут получить старую версию после деплоя.

### Пример `server { ... }`

```nginx
server {
  listen 80;
  server_name _;

  root /var/www/gogomarket;   # <- папка с Flutter web билдом (index.html, main.dart.js, assets/)
  index index.html;

  # ---------------------------
  # Сжатие (gzip)
  # ---------------------------
  gzip on;
  gzip_comp_level 6;
  gzip_min_length 1024;
  gzip_vary on;
  gzip_proxied any;
  gzip_types
    text/plain
    text/css
    text/xml
    application/json
    application/javascript
    application/xml
    application/xml+rss
    image/svg+xml;

  # ---------------------------
  # HTML: всегда свежий
  # ---------------------------
  location = /index.html {
    add_header Cache-Control "no-cache";
    try_files $uri =404;
  }

  # ---------------------------
  # Flutter bootstrap / main.dart.js
  # НЕ делаем long-cache
  # ---------------------------
  location = /main.dart.js {
    add_header Cache-Control "public, max-age=3600";
    try_files $uri =404;
  }

  # ---------------------------
  # Статика: можно кэшировать дольше
  # ---------------------------
  location /assets/ {
    add_header Cache-Control "public, max-age=604800";
    try_files $uri =404;
  }

  location ~* \.(?:png|jpg|jpeg|gif|webp|svg|ico|woff2|woff|ttf|eot|wasm)$ {
    add_header Cache-Control "public, max-age=604800";
    try_files $uri =404;
  }

  # ---------------------------
  # SPA fallback (Flutter router)
  # ---------------------------
  location / {
    try_files $uri $uri/ /index.html;
  }
}
```

### Если есть Brotli (опционально)

Если nginx собран с модулем brotli, можно добавить:

```nginx
brotli on;
brotli_comp_level 5;
brotli_types text/plain text/css application/javascript application/json image/svg+xml;
```

### Быстрая проверка заголовков

```bash
curl -I http://<host>/index.html
curl -I http://<host>/main.dart.js
curl -I http://<host>/assets/AssetManifest.json
```

