# Автодеплой (вариант 1): GitHub Actions → SSH → `deploy_web.sh`

## Что это даёт
- При каждом `git push` в выбранную ветку GitHub сам подключается к серверу по SSH и запускает деплой.
- Не нужно вручную заходить на сервер и выполнять команды.

---

## 1) Настройка сервера (один раз)

### 1.1 Создать пользователя `deploy` и дать доступ по ключу

На сервере `165.232.81.31` (под root):

```bash
adduser deploy
usermod -aG sudo deploy
mkdir -p /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
touch /home/deploy/.ssh/authorized_keys
chmod 600 /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh
```

Добавьте публичный ключ деплоя в:
`/home/deploy/.ssh/authorized_keys`

### 1.2 Passwordless sudo (важно: чтобы деплой был неинтерактивным)

`scripts/deploy_web.sh` использует `sudo -n` (без запроса пароля). Нужно разрешить `deploy` выполнять нужные команды без пароля.

Самый безопасный минимум — разрешить только:
- `rsync` в `/var/www/gogomarket`
- `systemctl reload nginx`
- запись `.last_build_id`

Пример (упрощённо, можно потом ужесточать):

```bash
cat >/etc/sudoers.d/deploy-web <<'EOF'
deploy ALL=(root) NOPASSWD: /usr/bin/rsync, /usr/bin/tee, /usr/bin/systemctl reload nginx, /bin/mkdir
EOF
chmod 440 /etc/sudoers.d/deploy-web
```

### 1.3 Важно про Flutter

Деплой запускает `flutter build web`. У пользователя `deploy` должен быть доступ к Flutter бинарнику.

Рекомендуется установить Flutter в путь, доступный `deploy`, например:
`/opt/flutter/bin/flutter`

И затем в `scripts/deploy_web.sh` передавать `FLUTTER_BIN=/opt/flutter/bin/flutter` (или сделать этот путь дефолтным).

---

## 2) GitHub Secrets (один раз)

В GitHub репозитории:
`Settings → Secrets and variables → Actions → New repository secret`

Добавить:
- `DEPLOY_HOST` = `165.232.81.31`
- `DEPLOY_USER` = `deploy`
- `DEPLOY_SSH_KEY` = приватный ключ (PEM) для SSH в `deploy@165.232.81.31`
- `DEPLOY_PROJECT_DIR` = `/root/projects/video-marketplace-app` (или другой путь, где лежит git-репа на сервере)

---

## 3) Workflow

Файл: `.github/workflows/deploy_web.yml`

- Триггер: push в ветку `cursor/what-has-been-done-5e03` (можно поменять на `feature/initial-upload` / `main`).
- На сервере выполняется:
  - `git fetch/checkout/pull` текущей ветки
  - `bash scripts/deploy_web.sh`

---

## 4) Как проверить

1) Сделайте любой коммит и `git push` в ветку деплоя.
2) В GitHub откройте `Actions` → выберите job `Deploy Flutter Web (SSH)` → проверьте лог.
3) Откройте сайт и проверьте `.last_build_id` на сервере в `/var/www/gogomarket/.last_build_id`.

