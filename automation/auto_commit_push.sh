#!/bin/bash

################################################################################
# AUTO COMMIT & PUSH SCRIPT
################################################################################
# Автоматический скрипт для коммита и пуша изменений в GitHub
# Использует интеллектуальное определение типа изменений и генерацию commit message
################################################################################

set -e  # Остановка при ошибке

# Загрузить конфигурацию
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/automation_config.sh"

# ============================================================================
# ФУНКЦИИ ЛОГИРОВАНИЯ
# ============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Вывод в консоль с цветом
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
        "DEBUG")
            if [[ "$DEBUG_MODE" == "true" ]]; then
                print_color "$COLOR_MAGENTA" "[$timestamp] [DEBUG] $message"
            fi
            ;;
    esac
    
    # Запись в лог-файл
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Запись ошибок в отдельный файл
    if [[ "$level" == "ERROR" ]]; then
        echo "[$timestamp] [ERROR] $message" >> "$ERROR_LOG"
    fi
}

# ============================================================================
# ФУНКЦИИ ПРОВЕРКИ
# ============================================================================

check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log "ERROR" "Не Git репозиторий. Выполните 'git init' сначала."
        exit 1
    fi
}

check_git_changes() {
    if git diff-index --quiet HEAD -- 2>/dev/null; then
        log "INFO" "Нет изменений для коммита"
        return 1
    fi
    return 0
}

check_last_commit_time() {
    if [[ ! -f "$LOG_DIR/.last_commit_time" ]]; then
        return 0
    fi
    
    local last_commit=$(cat "$LOG_DIR/.last_commit_time")
    local current_time=$(date +%s)
    local diff=$((current_time - last_commit))
    
    if [[ $diff -lt $MIN_COMMIT_INTERVAL ]]; then
        log "WARNING" "Слишком рано для нового коммита. Подождите $((MIN_COMMIT_INTERVAL - diff)) секунд"
        return 1
    fi
    return 0
}

check_forbidden_files() {
    log "DEBUG" "Проверка запрещенных файлов..."
    
    local changed_files=$(git diff --cached --name-only)
    
    for file in $changed_files; do
        if is_forbidden_file "$file"; then
            log "ERROR" "Обнаружен запрещенный файл: $file"
            log "ERROR" "Этот файл НЕ ДОЛЖЕН быть в коммите по соображениям безопасности"
            git reset HEAD "$file" 2>/dev/null
            return 1
        fi
    done
    
    return 0
}

check_secrets() {
    if [[ "$CHECK_SECRETS" != "true" ]]; then
        return 0
    fi
    
    log "DEBUG" "Проверка секретов в коде..."
    
    local changed_files=$(git diff --cached --name-only)
    local found_secrets=false
    
    for file in $changed_files; do
        for pattern in "${SECRET_PATTERNS[@]}"; do
            if git diff --cached "$file" | grep -qi "$pattern"; then
                log "WARNING" "Возможный секрет найден в файле: $file (паттерн: $pattern)"
                found_secrets=true
            fi
        done
    done
    
    if [[ "$found_secrets" == "true" ]]; then
        log "WARNING" "Обнаружены возможные секреты в коде. Проверьте файлы перед коммитом!"
        read -p "Продолжить коммит? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    return 0
}

# ============================================================================
# ФУНКЦИИ АНАЛИЗА ИЗМЕНЕНИЙ
# ============================================================================

get_changed_files() {
    git diff --name-only HEAD
}

get_changed_files_summary() {
    local files=$(git diff --name-status HEAD)
    local added=$(echo "$files" | grep -c "^A" || echo "0")
    local modified=$(echo "$files" | grep -c "^M" || echo "0")
    local deleted=$(echo "$files" | grep -c "^D" || echo "0")
    
    echo "Добавлено: $added, Изменено: $modified, Удалено: $deleted"
}

determine_commit_type() {
    log "DEBUG" "Определение типа изменений..."
    
    local changed_files=$(get_changed_files)
    local file_count=$(echo "$changed_files" | wc -l)
    
    if [[ $file_count -gt $MAX_FILES_PER_COMMIT ]]; then
        log "WARNING" "Изменено слишком много файлов ($file_count). Рекомендуется разбить на несколько коммитов"
    fi
    
    # Анализ содержимого изменений
    local diff_content=$(git diff HEAD)
    
    # Проверка на ключевые слова
    local commit_type="chore"
    local max_priority=0
    
    # fix
    for keyword in "${FIX_KEYWORDS[@]}"; do
        if echo "$diff_content" | grep -qi "$keyword"; then
            if [[ ${COMMIT_TYPES["fix"]} -gt $max_priority ]]; then
                commit_type="fix"
                max_priority=${COMMIT_TYPES["fix"]}
            fi
        fi
    done
    
    # feat
    for keyword in "${FEAT_KEYWORDS[@]}"; do
        if echo "$diff_content" | grep -qi "$keyword"; then
            if [[ ${COMMIT_TYPES["feat"]} -gt $max_priority ]]; then
                commit_type="feat"
                max_priority=${COMMIT_TYPES["feat"]}
            fi
        fi
    done
    
    # refactor
    for keyword in "${REFACTOR_KEYWORDS[@]}"; do
        if echo "$diff_content" | grep -qi "$keyword"; then
            if [[ ${COMMIT_TYPES["refactor"]} -gt $max_priority ]]; then
                commit_type="refactor"
                max_priority=${COMMIT_TYPES["refactor"]}
            fi
        fi
    done
    
    # docs
    if echo "$changed_files" | grep -qi "\.md$\|README\|doc"; then
        if [[ ${COMMIT_TYPES["docs"]} -gt $max_priority ]]; then
            commit_type="docs"
            max_priority=${COMMIT_TYPES["docs"]}
        fi
    fi
    
    # style
    for keyword in "${STYLE_KEYWORDS[@]}"; do
        if echo "$diff_content" | grep -qi "$keyword"; then
            if [[ ${COMMIT_TYPES["style"]} -gt $max_priority ]]; then
                commit_type="style"
                max_priority=${COMMIT_TYPES["style"]}
            fi
        fi
    done
    
    # test
    if echo "$changed_files" | grep -qi "test\|spec"; then
        if [[ ${COMMIT_TYPES["test"]} -gt $max_priority ]]; then
            commit_type="test"
            max_priority=${COMMIT_TYPES["test"]}
        fi
    fi
    
    echo "$commit_type"
}

get_commit_scope() {
    local changed_files=$(get_changed_files)
    
    # Определить scope на основе измененных файлов
    if echo "$changed_files" | grep -q "lib/.*auth"; then
        echo "auth"
    elif echo "$changed_files" | grep -q "lib/.*video"; then
        echo "video-player"
    elif echo "$changed_files" | grep -q "lib/.*api"; then
        echo "api"
    elif echo "$changed_files" | grep -q "lib/.*ui\|lib/.*widget"; then
        echo "ui"
    elif echo "$changed_files" | grep -q "web/"; then
        echo "web"
    elif echo "$changed_files" | grep -q "pubspec"; then
        echo "deps"
    elif echo "$changed_files" | grep -q "\.md$\|README"; then
        echo "docs"
    else
        echo "app"
    fi
}

generate_commit_message() {
    local commit_type="$1"
    local scope="$2"
    
    log "DEBUG" "Генерация commit message (type: $commit_type, scope: $scope)..."
    
    # Получить краткое описание изменений
    local changed_files=$(get_changed_files | head -5)
    local file_count=$(get_changed_files | wc -l)
    
    # Создать описание
    local description=""
    
    case "$commit_type" in
        "fix")
            description="исправлена ошибка в модуле $scope"
            ;;
        "feat")
            description="добавлена новая функциональность в $scope"
            ;;
        "refactor")
            description="рефакторинг кода в $scope"
            ;;
        "perf")
            description="улучшена производительность $scope"
            ;;
        "style")
            description="обновлено форматирование кода"
            ;;
        "docs")
            description="обновлена документация"
            ;;
        "test")
            description="добавлены/обновлены тесты для $scope"
            ;;
        "build")
            description="обновлена конфигурация сборки"
            ;;
        "ci")
            description="обновлен CI/CD pipeline"
            ;;
        *)
            description="обновлен код в $scope"
            ;;
    esac
    
    # Формат: type(scope): subject
    local subject="$commit_type($scope): $description"
    
    # Добавить тело с деталями
    local body="Изменено файлов: $file_count"
    body+="\n$(get_changed_files_summary)"
    body+="\n\nИзмененные файлы:"
    body+="\n$(echo "$changed_files" | sed 's/^/- /')"
    
    if [[ $file_count -gt 5 ]]; then
        body+="\n- ... и еще $((file_count - 5)) файл(ов)"
    fi
    
    # Добавить footer с ссылкой на автоматизацию
    local footer="Автоматический коммит от Cursor AI"
    
    # Вернуть полное сообщение
    echo -e "$subject\n\n$body\n\n$footer"
}

# ============================================================================
# ФУНКЦИИ GIT ОПЕРАЦИЙ
# ============================================================================

git_add_all() {
    log "INFO" "Добавление изменений в staging area..."
    
    if [[ "$AUTO_ADD_ALL" == "true" ]]; then
        git add -A
    else
        git add -u  # Только измененные файлы, не новые
    fi
    
    # Показать что добавлено
    local staged=$(git diff --cached --name-only | wc -l)
    log "INFO" "Добавлено файлов в staging: $staged"
}

git_commit() {
    local message="$1"
    
    log "INFO" "Создание коммита..."
    
    if git commit -m "$message"; then
        log "SUCCESS" "Коммит создан успешно"
        
        # Сохранить время последнего коммита
        date +%s > "$LOG_DIR/.last_commit_time"
        
        # Записать в лог коммитов
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$COMMIT_LOG"
        
        return 0
    else
        log "ERROR" "Ошибка при создании коммита"
        return 1
    fi
}

git_pull_rebase() {
    if [[ "$PULL_BEFORE_PUSH" != "true" ]]; then
        return 0
    fi
    
    log "INFO" "Получение последних изменений с remote..."
    
    local pull_cmd="git pull"
    if [[ "$USE_REBASE" == "true" ]]; then
        pull_cmd="git pull --rebase"
    fi
    
    if timeout $GIT_TIMEOUT $pull_cmd; then
        log "SUCCESS" "Pull выполнен успешно"
        return 0
    else
        log "ERROR" "Ошибка при pull. Возможно есть конфликты"
        return 1
    fi
}

git_push() {
    if [[ "$AUTO_PUSH" != "true" ]]; then
        log "INFO" "Автоматический push отключен"
        return 0
    fi
    
    local current_branch=$(git branch --show-current)
    log "INFO" "Отправка изменений в remote (ветка: $current_branch)..."
    
    local attempt=1
    while [[ $attempt -le $PUSH_RETRY_COUNT ]]; do
        log "DEBUG" "Попытка push #$attempt из $PUSH_RETRY_COUNT"
        
        if timeout $GIT_TIMEOUT git push origin "$current_branch"; then
            log "SUCCESS" "Push выполнен успешно в ветку $current_branch"
            
            # Проверить статус GitHub Actions (опционально)
            if command -v gh &> /dev/null; then
                log "INFO" "Проверка статуса GitHub Actions..."
                gh run list --limit 1
            fi
            
            return 0
        else
            log "WARNING" "Попытка push #$attempt не удалась"
            
            if [[ $attempt -lt $PUSH_RETRY_COUNT ]]; then
                log "INFO" "Повтор через $RETRY_DELAY секунд..."
                sleep $RETRY_DELAY
                
                # Попробовать pull перед повторной попыткой
                git_pull_rebase
            fi
        fi
        
        ((attempt++))
    done
    
    log "ERROR" "Не удалось выполнить push после $PUSH_RETRY_COUNT попыток"
    return 1
}

# ============================================================================
# ГЛАВНАЯ ФУНКЦИЯ
# ============================================================================

main() {
    log "INFO" "========================================="
    log "INFO" "AUTO COMMIT & PUSH - СТАРТ"
    log "INFO" "Проект: $PROJECT_NAME"
    log "INFO" "========================================="
    
    # Переход в директорию проекта
    if [[ -n "$PROJECT_PATH" ]] && [[ -d "$PROJECT_PATH" ]]; then
        cd "$PROJECT_PATH"
        log "INFO" "Рабочая директория: $PROJECT_PATH"
    else
        log "INFO" "Рабочая директория: $(pwd)"
    fi
    
    # Проверка что это git репозиторий
    check_git_repo
    
    # Проверка наличия изменений
    if ! check_git_changes; then
        log "INFO" "Нет изменений для коммита. Выход."
        exit 0
    fi
    
    log "INFO" "Обнаружены изменения в репозитории"
    
    # Проверка времени последнего коммита
    if ! check_last_commit_time; then
        exit 0
    fi
    
    # Показать статус
    log "INFO" "Статус репозитория:"
    git status --short
    
    # Добавить файлы в staging
    git_add_all
    
    # Проверка запрещенных файлов
    if ! check_forbidden_files; then
        log "ERROR" "Обнаружены запрещенные файлы. Коммит отменен."
        exit 1
    fi
    
    # Проверка секретов
    if ! check_secrets; then
        log "ERROR" "Проверка секретов не пройдена. Коммит отменен."
        exit 1
    fi
    
    # Определить тип изменений
    local commit_type=$(determine_commit_type)
    log "INFO" "Тип изменений: $commit_type"
    
    # Определить scope
    local scope=$(get_commit_scope)
    log "INFO" "Scope: $scope"
    
    # Сгенерировать commit message
    local commit_message=$(generate_commit_message "$commit_type" "$scope")
    
    log "INFO" "Commit message:"
    echo "$commit_message" | while IFS= read -r line; do
        log "INFO" "  $line"
    done
    
    # Создать коммит
    if ! git_commit "$commit_message"; then
        log "ERROR" "Не удалось создать коммит"
        exit 1
    fi
    
    # Pull перед push
    if ! git_pull_rebase; then
        log "ERROR" "Не удалось выполнить pull. Проверьте конфликты вручную"
        exit 1
    fi
    
    # Push в remote
    if ! git_push; then
        log "ERROR" "Не удалось выполнить push"
        exit 1
    fi
    
    log "SUCCESS" "========================================="
    log "SUCCESS" "АВТОМАТИЧЕСКИЙ КОММИТ И PUSH ЗАВЕРШЕН!"
    log "SUCCESS" "========================================="
    
    # Показать информацию о деплое
    if should_auto_deploy; then
        log "INFO" ""
        log "INFO" "Ветка '$current_branch' настроена для автоматического деплоя"
        log "INFO" "GitHub Actions начнет сборку и деплой на сервер"
        log "INFO" "Отслеживайте прогресс: $GITHUB_URL/actions"
        log "INFO" ""
    fi
}

# ============================================================================
# ЗАПУСК СКРИПТА
# ============================================================================

# Обработка аргументов командной строки
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            echo "Использование: $0 [опции]"
            echo ""
            echo "Опции:"
            echo "  -h, --help          Показать эту справку"
            echo "  -d, --debug         Включить debug режим"
            echo "  --no-push           Не выполнять push"
            echo "  --dry-run           Показать что будет сделано без выполнения"
            echo ""
            exit 0
            ;;
        --debug|-d)
            DEBUG_MODE=true
            log "INFO" "Debug режим включен"
            shift
            ;;
        --no-push)
            AUTO_PUSH=false
            log "INFO" "Push отключен"
            shift
            ;;
        --dry-run)
            log "INFO" "DRY RUN режим - изменения не будут применены"
            check_git_repo
            if check_git_changes; then
                echo "Изменения:"
                git status --short
                echo ""
                echo "Commit type: $(determine_commit_type)"
                echo "Scope: $(get_commit_scope)"
                echo ""
                echo "Commit message:"
                generate_commit_message "$(determine_commit_type)" "$(get_commit_scope)"
            else
                echo "Нет изменений"
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
