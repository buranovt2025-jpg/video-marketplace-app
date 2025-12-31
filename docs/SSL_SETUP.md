## SSL для `165.232.81.31` (чтобы убрать “Не защищено” и вернуть Service Worker/PWA)

Сейчас на проде используется self‑signed сертификат. На таких сайтах браузер:
- показывает “Не защищено”,
- **ломает регистрацию Service Worker** (поэтому у нас PWA отключён).

### Вариант A (правильный): домен + Let’s Encrypt

1) Купить/подключить домен (например `gogomarket.uz`) и направить A‑record на IP сервера `165.232.81.31`.
2) На сервере установить certbot:

```bash
sudo apt update
sudo apt install -y certbot python3-certbot-nginx
```

3) Выпустить сертификат под nginx:

```bash
sudo certbot --nginx -d gogomarket.uz -d www.gogomarket.uz
```

4) Проверить авто‑продление:

```bash
sudo certbot renew --dry-run
```

5) После нормального SSL можно:
- вернуть PWA (`flutter build web --release --pwa-strategy=offline-first`)
- раскомментировать/включить service worker регистрацию в `web/index.html` (если отключали вручную).

### Вариант B (временный): оставить self‑signed

Если домена пока нет — можно оставить self‑signed, но тогда:
- Service Worker на Web будет нестабилен/сломается,
- лучше продолжать деплоить с `--pwa-strategy=none` (как сейчас в `scripts/deploy_web.sh`).

### Проверка
- В браузере должен быть “замочек” (валидный TLS).
- В DevTools → Application → Service Workers: worker регистрируется без SSL ошибок.

