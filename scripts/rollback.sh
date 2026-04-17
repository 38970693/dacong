#!/bin/bash

# ============================================
# DaCong 回滚脚本
# ============================================
# 用途: 回滚到上一个稳定版本
# 使用: ./scripts/rollback.sh [version]

set -e
set -u

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 加载环境变量
if [ -f "$PROJECT_ROOT/.env.test" ]; then
    set -a
    source "$PROJECT_ROOT/.env.test"
    set +a
else
    log_error "缺少 .env.test 文件"
    exit 1
fi

# 备份目录
BACKUP_DIR="$PROJECT_ROOT/.backups"
mkdir -p "$BACKUP_DIR"

# ============================================
# 创建当前状态备份
# ============================================
create_backup() {
    log_info "创建当前状态备份..."

    local backup_name="backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_name"

    mkdir -p "$backup_path"

    # 备份数据库
    log_info "备份数据库..."
    pg_dump "$DATABASE_URL" > "$backup_path/database.sql"

    # 备份配置文件
    log_info "备份配置文件..."
    cp "$PROJECT_ROOT/.env.test" "$backup_path/.env.test"

    # 记录当前 git commit
    cd "$PROJECT_ROOT"
    git rev-parse HEAD > "$backup_path/git_commit.txt"

    log_success "备份完成: $backup_path"
    echo "$backup_path"
}

# ============================================
# 列出可用的备份
# ============================================
list_backups() {
    log_info "可用的备份:"
    echo ""

    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR")" ]; then
        log_warning "没有可用的备份"
        return 1
    fi

    local index=1
    for backup in "$BACKUP_DIR"/backup_*; do
        if [ -d "$backup" ]; then
            local backup_name=$(basename "$backup")
            local backup_date=$(echo "$backup_name" | sed 's/backup_//' | sed 's/_/ /')

            if [ -f "$backup/git_commit.txt" ]; then
                local git_commit=$(cat "$backup/git_commit.txt")
                echo "  $index. $backup_date (commit: ${git_commit:0:8})"
            else
                echo "  $index. $backup_date"
            fi

            index=$((index + 1))
        fi
    done

    echo ""
}

# ============================================
# 回滚数据库
# ============================================
rollback_database() {
    local backup_path="$1"

    log_info "回滚数据库..."

    if [ ! -f "$backup_path/database.sql" ]; then
        log_error "备份文件不存在: $backup_path/database.sql"
        return 1
    fi

    # 确认操作
    log_warning "警告: 这将覆盖当前数据库！"
    read -p "确认继续? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        log_info "取消回滚"
        return 1
    fi

    # 删除现有数据
    log_info "清理现有数据..."
    psql "$DATABASE_URL" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

    # 恢复备份
    log_info "恢复数据库备份..."
    psql "$DATABASE_URL" < "$backup_path/database.sql"

    log_success "数据库回滚完成"
}

# ============================================
# 回滚代码
# ============================================
rollback_code() {
    local backup_path="$1"

    log_info "回滚代码..."

    if [ ! -f "$backup_path/git_commit.txt" ]; then
        log_warning "没有 git commit 信息，跳过代码回滚"
        return 0
    fi

    local target_commit=$(cat "$backup_path/git_commit.txt")

    cd "$PROJECT_ROOT"

    # 确认操作
    log_warning "警告: 这将重置代码到 commit $target_commit"
    read -p "确认继续? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        log_info "取消代码回滚"
        return 1
    fi

    # 回滚代码
    git reset --hard "$target_commit"

    log_success "代码回滚完成"
}

# ============================================
# 回滚 Edge Functions
# ============================================
rollback_functions() {
    log_info "重新部署 Edge Functions..."

    cd "$PROJECT_ROOT/dacong-api"

    local functions=(
        "get-recommendations"
        "search-content"
        "get-content-detail"
        "get-weekly-report"
        "submit-feedback"
    )

    for func in "${functions[@]}"; do
        if [ -d "supabase/functions/$func" ]; then
            log_info "部署函数: $func"
            supabase functions deploy "$func" || {
                log_warning "函数部署失败: $func"
            }
        fi
    done

    log_success "Edge Functions 重新部署完成"
}

# ============================================
# 快速回滚（回滚到上一个版本）
# ============================================
quick_rollback() {
    log_info "执行快速回滚..."

    # 创建当前状态备份
    local current_backup=$(create_backup)
    echo ""

    # 获取最新的备份（排除刚创建的）
    local latest_backup=$(ls -t "$BACKUP_DIR"/backup_* | grep -v "$(basename "$current_backup")" | head -n 1)

    if [ -z "$latest_backup" ]; then
        log_error "没有可用的备份进行回滚"
        exit 1
    fi

    log_info "回滚到: $(basename "$latest_backup")"
    echo ""

    # 执行回滚
    rollback_database "$latest_backup"
    echo ""

    rollback_code "$latest_backup"
    echo ""

    rollback_functions
    echo ""

    log_success "快速回滚完成！"
}

# ============================================
# 交互式回滚
# ============================================
interactive_rollback() {
    log_info "交互式回滚"
    echo ""

    # 列出备份
    list_backups

    # 选择备份
    read -p "选择要回滚的备份编号 (或按 Enter 取消): " backup_index

    if [ -z "$backup_index" ]; then
        log_info "取消回滚"
        exit 0
    fi

    # 获取选中的备份
    local selected_backup=$(ls -t "$BACKUP_DIR"/backup_* | sed -n "${backup_index}p")

    if [ -z "$selected_backup" ]; then
        log_error "无效的备份编号"
        exit 1
    fi

    log_info "选择的备份: $(basename "$selected_backup")"
    echo ""

    # 创建当前状态备份
    create_backup
    echo ""

    # 执行回滚
    rollback_database "$selected_backup"
    echo ""

    rollback_code "$selected_backup"
    echo ""

    rollback_functions
    echo ""

    log_success "回滚完成！"
}

# ============================================
# 主流程
# ============================================
main() {
    log_info "=========================================="
    log_info "DaCong 回滚工具"
    log_info "=========================================="
    echo ""

    # 检查参数
    if [ $# -eq 0 ]; then
        # 无参数，执行快速回滚
        quick_rollback
    elif [ "$1" = "list" ]; then
        # 列出备份
        list_backups
    elif [ "$1" = "interactive" ] || [ "$1" = "-i" ]; then
        # 交互式回滚
        interactive_rollback
    else
        log_error "未知参数: $1"
        echo ""
        echo "用法:"
        echo "  ./scripts/rollback.sh              # 快速回滚到上一个版本"
        echo "  ./scripts/rollback.sh list         # 列出所有备份"
        echo "  ./scripts/rollback.sh interactive  # 交互式选择回滚版本"
        exit 1
    fi
}

# 捕获错误
trap 'log_error "回滚失败，请检查错误信息"; exit 1' ERR

main "$@"
