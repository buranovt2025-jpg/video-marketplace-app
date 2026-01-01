# Deploy backend on the same server (165.232.81.31)

Цель: запустить FastAPI backend (из `backend/`) на **том же сервере**, где nginx уже проксирует `/api` на `127.0.0.1:8000`.

## 0) Важно

- Этот backend модуль **не заменяет** ваш полный backend (products/orders/chat).  
  Он добавляет endpoints для **uploads** и **reviews**. Интегрировать нужно в существующий backend, либо расширять этот модуль.
- Если на сервере уже работает backend на `127.0.0.1:8000`, новый сервис конфликтует по порту.

## 1) Установка зависимостей (Ubuntu)

```bash
sudo apt update
sudo apt install -y python3-venv python3-pip
```

## 2) Развернуть код на сервере

Вариант A (рекомендуется): использовать тот же checkout репозитория, что и деплой web (`DEPLOY_PROJECT_DIR`).

Проверить на сервере, где репозиторий:

```bash
cd /home/deploy/projects/video-marketplace-app  # пример
git pull origin cursor/what-has-been-done-5e03
```

## 3) Создать env-файл с ключами Spaces

Создайте файл, например:

`/etc/gogomarket-backend.env`

Содержимое — по `backend/.env.example` (ВАЖНО: реальные значения):

```bash
S3_ENDPOINT=https://fra1.digitaloceanspaces.com
S3_REGION=fra1
S3_BUCKET=gogomarket-media
S3_ACCESS_KEY_ID=...
S3_SECRET_ACCESS_KEY=...
S3_PUBLIC_BASE_URL=https://gogomarket-media.fra1.digitaloceanspaces.com
UPLOAD_URL_TTL_SECONDS=900
```

Права:

```bash
sudo chown root:root /etc/gogomarket-backend.env
sudo chmod 600 /etc/gogomarket-backend.env
```

## 4) Создать venv и поставить requirements

```bash
cd /home/deploy/projects/video-marketplace-app
python3 -m venv backend/.venv
backend/.venv/bin/pip install -r backend/requirements.txt
```

## 5) Systemd service

Скопируйте unit:

```bash
sudo cp backend/deploy/gogomarket-backend.service /etc/systemd/system/gogomarket-backend.service
sudo systemctl daemon-reload
sudo systemctl enable --now gogomarket-backend
sudo systemctl status gogomarket-backend --no-pager
```

Логи:

```bash
sudo journalctl -u gogomarket-backend -f
```

## 6) Проверка

```bash
curl -fsS http://127.0.0.1:8000/healthz
```

Проверить endpoints:

```bash
RUN_BACKEND_CHECKS=1 bash scripts/smoke_test_prod.sh
```

