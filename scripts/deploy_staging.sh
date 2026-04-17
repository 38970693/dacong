#!/bin/bash

# ============================================
# DaCong Staging 环境部署脚本
# ============================================
# 用途: 自动部署到 Staging 环境
# 使用: ./scripts/deploy_staging.sh

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
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> deployment-staging.log
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $1" >> deployment-staging.log
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING] $1" >> deployment-staging.log
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> deployment-staging.log
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 环境变量
ENVIRONMENT="staging"
DEPLOY_VERSION="${CI_COMMIT_SHORT_SHA:-$(git rev-parse --short HEAD)}"
DEPLOY_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ============================================
# 前置检查
# ============================================
pre_deployment_checks() {
    log_info "=========================================="
    log_info "DaCong Staging 部署"
    log_info "=========================================="
    log_info "版本: $DEPLOY_VERSION"
    log_info "时间: $DEPLOY_TIMESTAMP"
    echo ""

    # 检查必需的环境变量
    log_info "检查环境变量..."

    local required_vars=(
        "SUPABASE_URL"
        "SUPABASE_SERVICE_ROLE_KEY"
        "STAGING_DEPLOY_HOOK"
    )

    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            log_error "缺少环境变量: $var"
            exit 1
        fi
    done

    log_success "环境变量检查通过"
}

# ============================================
# 创建部署备份
# ============================================
create_deployment_backup() {
    log_info "创建部署前备份..."

    local backup_name="staging_backup_${DEPLOY_TIMESTAMP}"

    # 记录当前版本信息
    cat > "backup_${backup_name}.json" <<EOF
{
  "environment": "staging",
  "version": "$DEPLOY_VERSION",
  "timestamp": "$DEPLOY_TIMESTAMP",
  "git_commit": "$(git rev-parse HEAD)",
  "git_branch": "$(git rev-parse --abbrev-ref HEAD)"
}
EOF

    log_success "备份信息已保存"
}

# ============================================
# 部署 Supabase Edge Functions
# ============================================
deploy_edge_functions() {
    log_info "部署 Edge Functions..."

    cd "$PROJECT_ROOT/dacong-api"

    # 检查 Supabase CLI
    if ! command -v supabase &> /dev/null; then
        log_warning "Supabase CLI 未安装，跳过 Edge Functions 部署"
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
            log_info "部署函数: $func"
            supabase functions deploy "$func" --project-ref "$SUPABASE_PROJECT_REF" || {
                log_error "函数部署失败: $func"
                return 1
            }
        fi
    done

    log_success "Edge Functions 部署完成"
}

# ============================================
# 部署前端应用
# ============================================
deploy_frontend() {
    log_info "部署前端应用..."

    # 触发 Vercel/Netlify 部署钩子
    if [ -n "${STAGING_DEPLOY_HOOK:-}" ]; then
        log_info "触发前端部署钩子..."

        curl -X POST "$STAGING_DEPLOY_HOOK" \
            -H "Content-Type: application/json" \
            -d "{\"ref\":\"$CI_COMMIT_REF_NAME\",\"sha\":\"$DEPLOY_VERSION\"}" || {
            log_error "前端部署钩子触发失败"
            return 1
        }

        log_success "前端部署已触发"
    else
        log_warning "未配置前端部署钩子，跳过"
    fi
}

# ============================================
# 运行数据库迁移
# ============================================
run_database_migrations() {
    log_info "运行数据库迁移..."

    cd "$PROJECT_ROOT/dacong-api"

    if [ -d "supabase/migrations" ] && [ "$(ls -A supabase/migrations)" ]; then
        if command -v supabase &> /dev/null; then
            supabase db push --project-ref "$SUPABASE_PROJECT_REF" || {
                log_error "数据库迁移失败"
                return 1
            }
            log_success "数据库迁移完成"
        else
            log_warning "Supabase CLI 未安装，跳过数据库迁移"
        fi
    else
        log_info "没有待执行的数据库迁移"
    fi
}

# ============================================
# 健康检查
# ============================================
health_check() {
    log_info "执行健康检查..."

    local max_attempts=30
    local attempt=1
    local health_url="${STAGING_HEALTH_CHECK_URL:-https://staging.dacong.ai/health}"

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
# 部署后验证
# ============================================
post_deployment_verification() {
    log_info "执行部署后验证..."

    # 验证 API 端点
    log_info "验证 API 端点..."

    local api_endpoints=(
        "/api/health"
        "/api/recommendations"
    )

    for endpoint in "${api_endpoints[@]}"; do
        local url="https://staging.dacong.ai${endpoint}"
        if curl -f -s -o /dev/null "$url"; then
            log_success "端点可用: $endpoint"
        else
            log_warning "端点不可用: $endpoint"
        fi
    done

    log_success "部署后验证完成"
}

# ============================================
# 发送部署通知
# ============================================
send_deployment_notification() {
    log_info "发送部署通知..."

    local status="$1"
    local message="Staging 部署 $status\n版本: $DEPLOY_VERSION\n时间: $DEPLOY_TIMESTAMP"

    # 发送到 Slack/Discord/钉钉等
    if [ -n "${NOTIFICATION_WEBHOOK:-}" ]; then
        curl -X POST "$NOTIFICATION_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"$message\"}" || true
    fi

    log_info "通知已发送"
}

# ============================================
# 主流程
# ============================================
main() {
    # 前置检查
    pre_deployment_checks

    # 创建备份
    create_deployment_backup
    echo ""

    # 运行数据库迁移
    run_database_migrations
    echo ""

    # 部署 Edge Functions
    deploy_edge_functions
    echo ""

    # 部署前端
    deploy_frontend
    echo ""

    # 健康检查
    health_check
    echo ""

    # 部署后验证
    post_deployment_verification
    echo ""

    # 发送成功通知
    send_deployment_notification "成功"

    log_success "=========================================="
    log_success "Staging 部署完成！"
    log_success "版本: $DEPLOY_VERSION"
    log_success "环境: https://staging.dacong.ai"
    log_success "=========================================="
}

# 捕获错误
trap 'log_error "部署失败，请检查错误信息"; send_deployment_notification "失败"; exit 1' ERR

main "$@"
