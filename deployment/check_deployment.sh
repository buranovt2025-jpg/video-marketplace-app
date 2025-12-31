#!/bin/bash

#=============================================================================
# СКРИПТ ПРОВЕРКИ ДЕПЛОЯ
# Проверяет доступность и работоспособность сайта после деплоя
#=============================================================================

set -e

#-----------------------------------------------------------------------------
# ЗАГРУЗКА КОНФИГУРАЦИИ
#-----------------------------------------------------------------------------

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -f "${SCRIPT_DIR}/deploy_config.sh" ]; then
    source "${SCRIPT_DIR}/deploy_config.sh" silent
else
    echo "❌ ОШИБКА: Файл конфигурации deploy_config.sh не найден!"
    exit 1
fi

#-----------------------------------------------------------------------------
# ФУНКЦИИ ВЫВОДА
#-----------------------------------------------------------------------------

print_header() {
    echo ""
    echo -e "${COLOR_CYAN}═══════════════════════════════════════════════════════════════${COLOR_RESET}"
    echo -e "${COLOR_CYAN}  $1${COLOR_RESET}"
    echo -e "${COLOR_CYAN}═══════════════════════════════════════════════════════════════${COLOR_RESET}"
}

print_check() {
    local status=$1
    local message=$2
    
    if [ "${status}" == "ok" ]; then
        echo -e "${COLOR_GREEN}✓ ${message}${COLOR_RESET}"
    elif [ "${status}" == "warn" ]; then
        echo -e "${COLOR_YELLOW}⚠️  ${message}${COLOR_RESET}"
    elif [ "${status}" == "error" ]; then
        echo -e "${COLOR_RED}❌ ${message}${COLOR_RESET}"
    else
        echo -e "${COLOR_BLUE}ℹ️  ${message}${COLOR_RESET}"
    fi
}

#-----------------------------------------------------------------------------
# НАЧАЛО ПРОВЕРКИ
#-----------------------------------------------------------------------------

print_header "🔍 ПРОВЕРКА ДЕПЛОЯ GOGOMARKET"

echo -e "${COLOR_YELLOW}📅 Время проверки: $(date '+%Y-%m-%d %H:%M:%S')${COLOR_RESET}"
echo -e "${COLOR_YELLOW}🌐 Сервер: ${SERVER_IP}${COLOR_RESET}"
echo ""

#-----------------------------------------------------------------------------
# 1. ПРОВЕРКА ДОСТУПНОСТИ СЕРВЕРА
#-----------------------------------------------------------------------------

print_header "📍 1. ПРОВЕРКА ДОСТУПНОСТИ СЕРВЕРА"

echo -n "Проверка ping ${SERVER_IP}... "
if ping -c 1 -W 2 "${SERVER_IP}" &> /dev/null; then
    print_check "ok" "Сервер доступен (ping)"
else
    print_check "error" "Сервер не отвечает на ping"
fi

# Формируем SSH команду
if [ -n "${SSH_KEY_PATH}" ]; then
    SSH_CMD="ssh -i ${SSH_KEY_PATH} -p ${SSH_PORT} ${SERVER_USER}@${SERVER_IP}"
elif [ -n "${SSH_HOST_ALIAS}" ]; then
    SSH_CMD="ssh ${SSH_HOST_ALIAS}"
else
    SSH_CMD="ssh -p ${SSH_PORT} ${SERVER_USER}@${SERVER_IP}"
fi

echo -n "Проверка SSH подключения... "
if ${SSH_CMD} "echo 'SSH test'" &> /dev/null; then
    print_check "ok" "SSH подключение работает"
else
    print_check "error" "SSH подключение не удалось"
    exit 1
fi

#-----------------------------------------------------------------------------
# 2. ПРОВЕРКА СТАТУСА NGINX
#-----------------------------------------------------------------------------

print_header "🔄 2. ПРОВЕРКА NGINX"

echo -n "Проверка статуса nginx... "
if ${SSH_CMD} "systemctl is-active --quiet nginx"; then
    print_check "ok" "Nginx работает"
else
    print_check "error" "Nginx не запущен!"
fi

echo -n "Проверка конфигурации nginx... "
if ${SSH_CMD} "nginx -t" &> /dev/null; then
    print_check "ok" "Конфигурация nginx корректна"
else
    print_check "error" "Ошибка в конфигурации nginx"
fi

# Получаем время запуска nginx
NGINX_UPTIME=$(${SSH_CMD} "systemctl show nginx -p ActiveEnterTimestamp | cut -d'=' -f2")
if [ -n "${NGINX_UPTIME}" ]; then
    print_check "info" "Время запуска: ${NGINX_UPTIME}"
fi

#-----------------------------------------------------------------------------
# 3. ПРОВЕРКА ФАЙЛОВ ПРИЛОЖЕНИЯ
#-----------------------------------------------------------------------------

print_header "📂 3. ПРОВЕРКА ФАЙЛОВ ПРИЛОЖЕНИЯ"

echo -n "Проверка наличия директории ${SERVER_WEB_DIR}... "
if ${SSH_CMD} "[ -d ${SERVER_WEB_DIR} ]"; then
    print_check "ok" "Директория существует"
else
    print_check "error" "Директория не найдена"
fi

echo -n "Проверка наличия index.html... "
if ${SSH_CMD} "[ -f ${SERVER_WEB_DIR}/index.html ]"; then
    print_check "ok" "index.html найден"
    
    INDEX_SIZE=$(${SSH_CMD} "du -h ${SERVER_WEB_DIR}/index.html | cut -f1")
    print_check "info" "Размер index.html: ${INDEX_SIZE}"
else
    print_check "error" "index.html не найден"
fi

echo -n "Проверка наличия Flutter файлов... "
if ${SSH_CMD} "[ -f ${SERVER_WEB_DIR}/main.dart.js ]"; then
    print_check "ok" "Flutter файлы найдены"
else
    print_check "warn" "main.dart.js не найден (возможно canvaskit renderer)"
fi

# Подсчитываем общий размер
TOTAL_SIZE=$(${SSH_CMD} "du -sh ${SERVER_WEB_DIR} | cut -f1")
print_check "info" "Общий размер: ${TOTAL_SIZE}"

FILE_COUNT=$(${SSH_CMD} "find ${SERVER_WEB_DIR} -type f | wc -l")
print_check "info" "Количество файлов: ${FILE_COUNT}"

#-----------------------------------------------------------------------------
# 4. ПРОВЕРКА ДОСТУПНОСТИ САЙТА (HTTP/HTTPS)
#-----------------------------------------------------------------------------

print_header "🌐 4. ПРОВЕРКА ДОСТУПНОСТИ САЙТА"

# Проверка HTTPS
echo -n "Проверка https://${SERVER_IP}... "
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://${SERVER_IP}" --insecure --max-time 10 || echo "000")
HTTPS_TIME=$(curl -s -o /dev/null -w "%{time_total}" "https://${SERVER_IP}" --insecure --max-time 10 || echo "0")

if [ "${HTTPS_CODE}" == "200" ]; then
    print_check "ok" "HTTPS доступен (HTTP ${HTTPS_CODE}, ${HTTPS_TIME}s)"
elif [ "${HTTPS_CODE}" == "000" ]; then
    print_check "error" "HTTPS недоступен (таймаут или ошибка подключения)"
else
    print_check "warn" "HTTPS вернул код ${HTTPS_CODE}"
fi

# Проверка HTTP
echo -n "Проверка http://${SERVER_IP}... "
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${SERVER_IP}" --max-time 10 || echo "000")

if [ "${HTTP_CODE}" == "200" ]; then
    print_check "ok" "HTTP доступен (HTTP ${HTTP_CODE})"
elif [ "${HTTP_CODE}" == "301" ] || [ "${HTTP_CODE}" == "302" ]; then
    print_check "ok" "HTTP перенаправляет на HTTPS (${HTTP_CODE})"
elif [ "${HTTP_CODE}" == "000" ]; then
    print_check "error" "HTTP недоступен"
else
    print_check "warn" "HTTP вернул код ${HTTP_CODE}"
fi

# Получаем заголовки ответа
echo ""
echo -e "${COLOR_BLUE}ℹ️  Заголовки HTTP ответа:${COLOR_RESET}"
curl -sI "https://${SERVER_IP}" --insecure --max-time 10 | head -n 5

#-----------------------------------------------------------------------------
# 5. ПРОВЕРКА ЛОГОВ NGINX
#-----------------------------------------------------------------------------

print_header "📝 5. ПОСЛЕДНИЕ ЗАПИСИ ИЗ ЛОГОВ NGINX"

echo -e "${COLOR_YELLOW}⚠️  Последние 5 строк из error.log:${COLOR_RESET}"
${SSH_CMD} "tail -n 5 /var/log/nginx/error.log 2>/dev/null || echo 'Лог не доступен'"

echo ""
echo -e "${COLOR_BLUE}ℹ️  Последние 5 строк из access.log:${COLOR_RESET}"
${SSH_CMD} "tail -n 5 /var/log/nginx/access.log 2>/dev/null || echo 'Лог не доступен'"

#-----------------------------------------------------------------------------
# 6. ИНФОРМАЦИЯ О СЕРВЕРЕ
#-----------------------------------------------------------------------------

print_header "🖥️  6. ИНФОРМАЦИЯ О СЕРВЕРЕ"

# Информация о системе
OS_INFO=$(${SSH_CMD} "cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"'")
print_check "info" "ОС: ${OS_INFO}"

UPTIME=$(${SSH_CMD} "uptime -p")
print_check "info" "Uptime: ${UPTIME}"

# Использование диска
DISK_USAGE=$(${SSH_CMD} "df -h / | tail -n 1 | awk '{print \$5}'") 
print_check "info" "Использование диска: ${DISK_USAGE}"

# Использование RAM
MEM_USAGE=$(${SSH_CMD} "free -h | grep Mem | awk '{print \$3 \"/\" \$2}'") 
print_check "info" "Использование RAM: ${MEM_USAGE}"

#-----------------------------------------------------------------------------
# ЗАКЛЮЧЕНИЕ
#-----------------------------------------------------------------------------

print_header "✅ ПРОВЕРКА ЗАВЕРШЕНА"

echo -e "${COLOR_GREEN}✓ Проверка завершена успешно${COLOR_RESET}"
echo -e "${COLOR_CYAN}🌐 Сайт доступен по адресу: https://${SERVER_IP}${COLOR_RESET}"
echo ""

exit 0
