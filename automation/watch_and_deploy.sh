#!/bin/bash

################################################################################
# WATCH AND DEPLOY SCRIPT
################################################################################
# Мониторинг файловой системы и автоматический коммит при изменениях
# Использует inotifywait для отслеживания изменений в реальном времени
################################################################################

set -e

# Загрузить конфигурацию
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/automation_config.sh"

# ============================================================================
# ПРОВЕРКА ЗАВИСИМОСТЕЙ
# ============================================================================

check_dependencies() {
    log "INFO" "Проверка зависимостей..."
    
    if ! command -v inotifywait &> /dev/null; then
        log "ERROR" "inotifywait не установлен. Установите: sudo apt-get install inotify-tools"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        log "ERROR" "git не установлен"
        exit 1
    fi
    
    log "SUCCESS" "Все зависимости установлены"
}

# ============================================================================
# ФУНКЦИИ ЛОГИРОВАНИЯ
# ============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")
            print_color "$COLOR_BLUE" "[$timestamp] [INFO] $message"
            ;;
        "SUCCESS")
            print_color "$COLOR_GREEN" "[$timestamp] [SUCCESS] $message"
            ;;
        "WARNING")
            print_color "$COLOR_YELLOW" "[$timestamp] [WARNING] $message"
            ;;
        "ERROR")
            print_color "$COLOR_RED" "[$timestamp] [ERROR] $message"
            ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# ============================================================================
# ФУНКЦИЯ МОНИТОРИНГА
# ============================================================================

watch_files() {
    log "INFO" "Начало мониторинга файлов в: $PROJECT_PATH"
    log "INFO" "Отслеживаемые директории: ${WATCH_DIRS[*]}"
    log "INFO" "Отслеживаемые расширения: ${WATCH_EXTENSIONS[*]}"
    log "INFO" "Задержка перед коммитом: $WATCH_DELAY секунд"
    log "INFO" ""
    log "INFO" "Нажмите Ctrl+C для остановки"
    log "INFO" "=========================================="
    
    # Переход в директорию проекта
    cd "$PROJECT_PATH" || exit 1
    
    # Построить список директорий для мониторинга
    local watch_paths=""
    for dir in "${WATCH_DIRS[@]}"; do
        if [ -e "$dir" ]; then
            watch_paths="$watch_paths $dir"
        fi
    done
    
    # Построить фильтр расширений
    local extension_filter=""
    for ext in "${WATCH_EXTENSIONS[@]}"; do
        extension_filter="$extension_filter --include \"*.$ext\""
    done
    
    # Построить фильтр игнорирования
    local ignore_filter=""
    for ignore_dir in "${IGNORE_DIRS[@]}"; do
        ignore_filter="$ignore_filter --exclude \"$ignore_dir\""
    done
    
    # Флаг для отслеживания изменений
    local changes_detected=false
    local last_change_time=0
    
    # Основной цикл мониторинга
    while true; do
        # Отслеживание изменений
        inotifywait -r -e modify,create,delete,move \
            --format '%:e %w%f' \
            $ignore_filter \
            $watch_paths 2>/dev/null | \
        while read -r event file; do
            # Проверить расширение файла
            local file_ext="${file##*.}"
            local should_process=false
            
            for ext in "${WATCH_EXTENSIONS[@]}"; do
                if [[ "$file_ext" == "$ext" ]]; then
                    should_process=true
                    break
                fi
            done
            
            if [[ "$should_process" == true ]]; then
                log "INFO" "Обнаружено изменение: $event $file"
                changes_detected=true
                last_change_time=$(date +%s)
            fi
        done &
        
        # Ожидание и проверка изменений
        sleep $WATCH_DELAY
        
        if [[ "$changes_detected" == true ]]; then
            local current_time=$(date +%s)
            local time_since_change=$((current_time - last_change_time))
            
            # Если прошло достаточно времени с последнего изменения
            if [[ $time_since_change -ge $WATCH_DELAY ]]; then
                log "INFO" "Запуск автоматического коммита..."
                log "INFO" "=========================================="
                
                # Запустить скрипт автокоммита
                if "$SCRIPT_DIR/auto_commit_push.sh"; then
                    log "SUCCESS" "Автоматический коммит выполнен успешно"
                else
                    log "ERROR" "Ошибка при выполнении автокоммита"
                fi
                
                log "INFO" "=========================================="
                log "INFO" "Продолжение мониторинга..."
                log "INFO" ""
                
                # Сбросить флаг
                changes_detected=false
            fi
        fi
    done
}

# ============================================================================
# ФУНКЦИЯ ОСТАНОВКИ
# ============================================================================

cleanup() {
    log "INFO" ""
    log "INFO" "=========================================="
    log "INFO" "Остановка мониторинга..."
    log "INFO" "=========================================="
    
    # Убить все дочерние процессы
    pkill -P $$ 2>/dev/null || true
    
    log "SUCCESS" "Мониторинг остановлен"
    exit 0
}

# Обработка Ctrl+C
trap cleanup SIGINT SIGTERM

# ============================================================================
# ГЛАВНАЯ ФУНКЦИЯ
# ============================================================================

main() {
    log "INFO" "=========================================="
    log "INFO" "WATCH AND DEPLOY - СТАРТ"
    log "INFO" "Проект: $PROJECT_NAME"
    log "INFO" "=========================================="
    
    # Проверка что watch mode включен
    if [[ "$WATCH_MODE_ENABLED" != "true" ]]; then
        log "WARNING" "Watch mode отключен в конфигурации"
        log "WARNING" "Установите WATCH_MODE_ENABLED=true в automation_config.sh"
        exit 0
    fi
    
    # Проверка зависимостей
    check_dependencies
    
    # Проверка существования директории проекта
    if [[ ! -d "$PROJECT_PATH" ]]; then
        log "ERROR" "Директория проекта не найдена: $PROJECT_PATH"
        exit 1
    fi
    
    # Проверка что это git репозиторий
    if ! git -C "$PROJECT_PATH" rev-parse --git-dir > /dev/null 2>&1; then
        log "ERROR" "$PROJECT_PATH не является git репозиторием"
        exit 1
    fi
    
    # Запуск мониторинга
    watch_files
}

# ============================================================================
# ЗАПУСК СКРИПТА
# ============================================================================

# Обработка аргументов
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            echo "Использование: $0 [опции]"
            echo ""
            echo "Опции:"
            echo "  -h, --help          Показать эту справку"
            echo "  -d, --daemon        Запустить в фоновом режиме"
            echo ""
            echo "Этот скрипт отслеживает изменения в файлах проекта"
            echo "и автоматически коммитит их в Git."
            echo ""
            echo "Для остановки нажмите Ctrl+C"
            echo "или используйте: pkill -f watch_and_deploy.sh"
            echo ""
            exit 0
            ;;
        --daemon|-d)
            log "INFO" "Запуск в фоновом режиме..."
            nohup "$0" > "$LOG_DIR/watch_daemon.log" 2>&1 &
            echo $! > "$LOG_DIR/watch.pid"
            log "SUCCESS" "Watch daemon запущен (PID: $!)"
            log "INFO" "Логи: $LOG_DIR/watch_daemon.log"
            log "INFO" "Для остановки: kill $(cat $LOG_DIR/watch.pid)"
            exit 0
            ;;
        --stop)
            if [[ -f "$LOG_DIR/watch.pid" ]]; then
                local pid=$(cat "$LOG_DIR/watch.pid")
                log "INFO" "Остановка watch daemon (PID: $pid)..."
                kill $pid 2>/dev/null || log "WARNING" "Процесс не найден"
                rm -f "$LOG_DIR/watch.pid"
                log "SUCCESS" "Watch daemon остановлен"
            else
                log "WARNING" "Watch daemon не запущен"
            fi
            exit 0
            ;;
        --status)
            if [[ -f "$LOG_DIR/watch.pid" ]]; then
                local pid=$(cat "$LOG_DIR/watch.pid")
                if ps -p $pid > /dev/null 2>&1; then
                    log "SUCCESS" "Watch daemon работает (PID: $pid)"
                else
                    log "WARNING" "Watch daemon не работает (PID файл существует, но процесс не найден)"
                    rm -f "$LOG_DIR/watch.pid"
                fi
            else
                log "INFO" "Watch daemon не запущен"
            fi
            exit 0
            ;;
        *)
            log "ERROR" "Неизвестная опция: $1"
            echo "Используйте --help для справки"
            exit 1
            ;;
    esac
done

# Запуск главной функции
main

exit 0
