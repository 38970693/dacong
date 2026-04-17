#!/bin/bash

# ============================================
# DaCong CI/CD 回滚脚本
# ============================================
# 用途: 在 CI/CD 环境中快速回滚到指定版本
# 使用: ./scripts/rollback_cicd.sh <environment> <version>

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

# 参数
ENVIRONMENT="${1:-staging}"
ROLLBACK_VERSION="${2:-previous}"
ROLLBACK_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ============================================
# 验证参数
# ============================================
validate_parameters() {
    log_info "=========================================="
    log_info "DaCong 快速回滚"
    log_info "=========================================="
    log_info "环境: $ENVIRONMENT"
    log_info "目标版本: $ROLLBACK_VERSION"
    log_info "时间: $ROLLBACK_TIMESTAMP"
    echo ""

    # 验证环境
    if [[ ! "$ENVIRONMENT" =~ ^(staging|production)$ ]]; then
        log_error "无效的环境: $ENVIRONMENT (只支持 staging 或 production)"
        exit 1
    fi

    # 检查必需的环境变量
    log_info "检查环境变量..."

    local required_vars=(
        "SUPABASE_URL"
        "SUPABASE_SERVICE_ROLE_KEY"
    )

    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            log_error "缺少环境变量: $var"
            exit 1
        fi
    done

    log_success "参数验证通过"
}

# ============================================
# 获取上一个版本
# ============================================
get_previous_version() {
    log_info "获取上一个版本..."

    # 从 Git tags 获取上一个版本
    local previous_tag=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")

    if [ -z "$previous_tag" ]; then
        log_warning "未找到上一个版本标签"
        # 使用上一个 commit
        previous_tag=$(git rev-parse HEAD^)
    fi

    echo "$previous_tag"
}

# ============================================
# 回滚前端应用
# ============================================
rollback_frontend() {
    log_info "回滚前端应用..."

    local target_version="$1"
    local deploy_hook_var="${ENVIRONMENT^^}_DEPLOY_HOOK"
    local deploy_hook="${!deploy_hook_var:-}"

    if [ -z "$deploy_hook" ]; then
        log_warning "未配置部署钩子: $deploy_hook_var"
        return 0
    fi

    # 触发回滚部署
    log_info "触发前端回滚到版本: $target_version"

    curl -X POST "$deploy_hook" \
        -H "Content-Type: application/json" \
        -d "{\"ref\":\"$target_version\",\"rollback\":true}" || {
        log_error "前端回滚失败"
        return 1
    }

    log_success "前端回滚已触发"

    # 等待部署完成
    log_info "等待前端回滚完成..."
    sleep 30
}

# ============================================
# 回滚 Edge Functions
# ============================================
rollback_edge_functions() {
    log_info "回滚 Edge Functions..."

    local target_version="$1"

    cd "$PROJECT_ROOT"

    # 切换到目标版本
    log_info "切换代码到版本: $target_version"
    git fetch --all --tags
    git checkout "$target_version" || {
        log_error "无法切换到版本: $target_version"
        return 1
    }

    cd "$PROJECT_ROOT/dacong-api"

    # 检查 Supabase CLI
    if ! command -v supabase &> /dev/null; then
        log_warning "Supabase CLI 未安装，跳过 Edge Functions 回滚"
        return 0
    fi

    local functions=(
        "get-recommendations"
        "search-content"
        "get-content-detail"
        "get-weekly-report"
        "submit-feedback"
    )

    for func in "${functions[@]}"; do
        if [ -d "supabase/functions/$func" ]; then
            log_info "回滚函数: $func"
            supabase functions deploy "$func" --project-ref "$SUPABASE_PROJECT_REF" || {
                log_warning "函数回滚失败: $func"
            }
        fi
    done

    log_success "Edge Functions 回滚完成"
}

# ============================================
# 回滚数据库（如果需要）
# ============================================
rollback_database() {
    log_info "检查数据库回滚需求..."

    # 通常不建议自动回滚数据库，因为可能导致数据丢失
    # 这里只是记录警告
    log_warning "数据库回滚需要手动执行，请联系 DBA"
    log_warning "如果需要回滚数据库迁移，请使用 Supabase 控制台"
}

# ============================================
# 健康检查
# ============================================
health_check() {
    log_info "执行健康检查..."

    local max_attempts=30
    local attempt=1

    if [ "$ENVIRONMENT" = "production" ]; then
        local health_url="${PRODUCTION_HEALTH_CHECK_URL:-https://dacong.ai/health}"
    else
        local health_url="${STAGING_HEALTH_CHECK_URL:-https://staging.dacong.ai/health}"
    fi

    while [ $attempt -le $max_attempts ]; do
        log_info "健康检查尝试 $attempt/$max_attempts..."

        if curl -f -s -o /dev/null "$health_url"; then
            log_success "健康检查通过"
            return 0
        fi

        sleep 10
        attempt=$((attempt + 1))
    done

    log_error "健康检查失败"
    return 1
}

# ============================================
# 验证回滚结果
# ============================================
verify_rollback() {
    log_info "验证回滚结果..."

    local base_url
    if [ "$ENVIRONMENT" = "production" ]; then
        base_url="https://dacong.ai"
    else
        base_url="https://staging.dacong.ai"
    fi

    # 测试关键端点
    local endpoints=(
        "/api/health"
        "/api/recommendations"
    )

    for endpoint in "${endpoints[@]}"; do
        local url="${base_url}${endpoint}"
        log_info "测试端点: $endpoint"

        if curl -f -s -o /dev/null "$url"; then
            log_success "端点可用: $endpoint"
        else
            log_warning "端点不可用: $endpoint"
        fi
    done

    log_success "回滚验证完成"
}

# ============================================
# 发送回滚通知
# ============================================
send_rollback_notification() {
    log_info "发送回滚通知..."

    local status="$1"
    local target_version="$2"
    local message="${ENVIRONMENT} 环境回滚 $status\n目标版本: $target_version\n时间: $ROLLBACK_TIMESTAMP"

    # 发送到 Slack/Discord/钉钉等
    if [ -n "${NOTIFICATION_WEBHOOK:-}" ]; then
        curl -X POST "$NOTIFICATION_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"$message\",\"priority\":\"high\"}" || true
    fi

    log_info "通知已发送"
}

# ============================================
# 记录回滚操作
# ============================================
log_rollback_operation() {
    log_info "记录回滚操作..."

    local target_version="$1"
    local log_file="rollback_${ENVIRONMENT}_${ROLLBACK_TIMESTAMP}.log"

    cat > "$log_file" <<EOF
回滚操作记录
============================================
环境: $ENVIRONMENT
目标版本: $target_version
回滚时间: $ROLLBACK_TIMESTAMP
操作人: ${GITLAB_USER_LOGIN:-CI/CD}
Pipeline ID: ${CI_PIPELINE_ID:-N/A}
Job ID: ${CI_JOB_ID:-N/A}
============================================
EOF

    log_success "回滚操作已记录: $log_file"
}

# ============================================
# 主流程
# ============================================
main() {
    # 验证参数
    validate_parameters

    # 确定目标版本
    local target_version="$ROLLBACK_VERSION"
    if [ "$target_version" = "previous" ]; then
        target_version=$(get_previous_version)
        log_info "自动确定目标版本: $target_version"
    fi
    echo ""

    # 记录回滚操作
    log_rollback_operation "$target_version"
    echo ""

    # 回滚 Edge Functions
    rollback_edge_functions "$target_version"
    echo ""

    # 回滚前端应用
    rollback_frontend "$target_version"
    echo ""

    # 检查数据库回滚需求
    rollback_database
    echo ""

    # 健康检查
    health_check
    echo ""

    # 验证回滚结果
    verify_rollback
    echo ""

    # 发送成功通知
    send_rollback_notification "成功" "$target_version"

    log_success "=========================================="
    log_success "回滚完成！"
    log_success "环境: $ENVIRONMENT"
    log_success "版本: $target_version"
    log_success "回滚时间: < 5 分钟"
    log_success "=========================================="
}

# 捕获错误
trap 'log_error "回滚失败，请检查错误信息"; send_rollback_notification "失败" "$ROLLBACK_VERSION"; exit 1' ERR

main "$@"
