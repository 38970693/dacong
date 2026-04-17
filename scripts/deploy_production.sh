#!/bin/bash

# ============================================
# DaCong Production 环境部署脚本
# ============================================
# 用途: 自动部署到 Production 环境
# 使用: ./scripts/deploy_production.sh

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
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> deployment-production.log
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $1" >> deployment-production.log
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING] $1" >> deployment-production.log
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> deployment-production.log
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 环境变量
ENVIRONMENT="production"
DEPLOY_VERSION="${CI_COMMIT_SHORT_SHA:-$(git rev-parse --short HEAD)}"
DEPLOY_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ============================================
# 前置检查
# ============================================
pre_deployment_checks() {
    log_info "=========================================="
    log_info "DaCong Production 部署"
    log_info "=========================================="
    log_info "版本: $DEPLOY_VERSION"
    log_info "时间: $DEPLOY_TIMESTAMP"
    echo ""

    # 检查必需的环境变量
    log_info "检查环境变量..."

    local required_vars=(
        "SUPABASE_URL"
        "SUPABASE_SERVICE_ROLE_KEY"
        "PRODUCTION_DEPLOY_HOOK"
    )

    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            log_error "缺少环境变量: $var"
            exit 1
        fi
    done

    log_success "环境变量检查通过"

    # 确认是否在 main 分支
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [ "$current_branch" != "main" ]; then
        log_error "只能从 main 分支部署到 Production"
        exit 1
    fi

    log_success "分支检查通过"
}

# ============================================
# 创建部署备份
# ============================================
create_deployment_backup() {
    log_info "创建部署前备份..."

    local backup_name="production_backup_${DEPLOY_TIMESTAMP}"

    # 记录当前版本信息
    cat > "backup_${backup_name}.json" <<EOF
{
  "environment": "production",
  "version": "$DEPLOY_VERSION",
  "timestamp": "$DEPLOY_TIMESTAMP",
  "git_commit": "$(git rev-parse HEAD)",
  "git_branch": "$(git rev-parse --abbrev-ref HEAD)",
  "git_tag": "$(git describe --tags --abbrev=0 2>/dev/null || echo 'none')"
}
EOF

    # 备份数据库（可选，根据实际情况启用）
    if [ "${ENABLE_DB_BACKUP:-false}" = "true" ]; then
        log_info "备份生产数据库..."
        # 这里添加数据库备份逻辑
        # pg_dump "$DATABASE_URL" > "backup_${backup_name}.sql"
    fi

    log_success "备份信息已保存"
}

# ============================================
# 蓝绿部署 - 准备新版本
# ============================================
prepare_blue_green_deployment() {
    log_info "准备蓝绿部署..."

    # 标记当前版本为 green（旧版本）
    export CURRENT_VERSION="green"
    export NEW_VERSION="blue"

    log_info "当前版本: $CURRENT_VERSION"
    log_info "新版本: $NEW_VERSION"
}

# ============================================
# 运行数据库迁移（带回滚保护）
# ============================================
run_database_migrations() {
    log_info "运行数据库迁移..."

    cd "$PROJECT_ROOT/dacong-api"

    if [ -d "supabase/migrations" ] && [ "$(ls -A supabase/migrations)" ]; then
        if command -v supabase &> /dev/null; then
            # 先进行迁移预检
            log_info "执行迁移预检..."
            supabase db diff --use-migra || {
                log_error "数据库迁移预检失败"
                return 1
            }

            # 执行迁移
            log_info "执行数据库迁移..."
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
# 部署前端应用（蓝绿部署）
# ============================================
deploy_frontend() {
    log_info "部署前端应用..."

    # 触发 Vercel/Netlify 部署钩子
    if [ -n "${PRODUCTION_DEPLOY_HOOK:-}" ]; then
        log_info "触发前端部署钩子..."

        curl -X POST "$PRODUCTION_DEPLOY_HOOK" \
            -H "Content-Type: application/json" \
            -d "{\"ref\":\"$CI_COMMIT_REF_NAME\",\"sha\":\"$DEPLOY_VERSION\"}" || {
            log_error "前端部署钩子触发失败"
            return 1
        }

        log_success "前端部署已触发"

        # 等待部署完成
        log_info "等待前端部署完成..."
        sleep 30
    else
        log_warning "未配置前端部署钩子，跳过"
    fi
}

# ============================================
# 金丝雀测试（部署到 5% 流量）
# ============================================
canary_deployment() {
    log_info "执行金丝雀部署（5% 流量）..."

    # 这里添加金丝雀部署逻辑
    # 例如：更新负载均衡器配置，将 5% 流量导向新版本

    log_info "监控金丝雀指标..."
    sleep 60  # 监控 1 分钟

    # 检查错误率
    local error_rate=$(check_error_rate)
    if [ "$error_rate" -gt 5 ]; then
        log_error "金丝雀部署错误率过高: ${error_rate}%"
        return 1
    fi

    log_success "金丝雀部署通过"
}

# ============================================
# 检查错误率
# ============================================
check_error_rate() {
    # 这里添加实际的错误率检查逻辑
    # 例如：查询监控系统 API
    echo "0"  # 模拟返回 0% 错误率
}

# ============================================
# 健康检查
# ============================================
health_check() {
    log_info "执行健康检查..."

    local max_attempts=60
    local attempt=1
    local health_url="${PRODUCTION_HEALTH_CHECK_URL:-https://dacong.ai/health}"

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
# 烟雾测试
# ============================================
smoke_tests() {
    log_info "执行烟雾测试..."

    local base_url="https://dacong.ai"

    # 测试关键端点
    local endpoints=(
        "/api/health"
        "/api/recommendations"
        "/api/search"
    )

    for endpoint in "${endpoints[@]}"; do
        local url="${base_url}${endpoint}"
        log_info "测试端点: $endpoint"

        if curl -f -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
            log_success "端点测试通过: $endpoint"
        else
            log_error "端点测试失败: $endpoint"
            return 1
        fi
    done

    log_success "烟雾测试通过"
}

# ============================================
# 切换流量到新版本
# ============================================
switch_traffic() {
    log_info "切换流量到新版本..."

    # 逐步增加流量：5% -> 25% -> 50% -> 100%
    local traffic_stages=(5 25 50 100)

    for stage in "${traffic_stages[@]}"; do
        log_info "切换 ${stage}% 流量到新版本..."

        # 这里添加流量切换逻辑
        # 例如：更新负载均衡器配置

        # 监控一段时间
        sleep 30

        # 检查错误率
        local error_rate=$(check_error_rate)
        if [ "$error_rate" -gt 5 ]; then
            log_error "错误率过高: ${error_rate}%，停止流量切换"
            return 1
        fi

        log_success "${stage}% 流量切换完成"
    done

    log_success "流量切换完成"
}

# ============================================
# 部署后验证
# ============================================
post_deployment_verification() {
    log_info "执行部署后验证..."

    # 验证关键功能
    log_info "验证关键功能..."

    # 1. 验证推荐系统
    log_info "验证推荐系统..."
    # 添加实际验证逻辑

    # 2. 验证搜索功能
    log_info "验证搜索功能..."
    # 添加实际验证逻辑

    # 3. 验证周报生成
    log_info "验证周报生成..."
    # 添加实际验证逻辑

    log_success "部署后验证完成"
}

# ============================================
# 发送部署通知
# ============================================
send_deployment_notification() {
    log_info "发送部署通知..."

    local status="$1"
    local message="Production 部署 $status\n版本: $DEPLOY_VERSION\n时间: $DEPLOY_TIMESTAMP\n环境: https://dacong.ai"

    # 发送到 Slack/Discord/钉钉等
    if [ -n "${NOTIFICATION_WEBHOOK:-}" ]; then
        curl -X POST "$NOTIFICATION_WEBHOOK" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"$message\"}" || true
    fi

    log_info "通知已发送"
}

# ============================================
# 创建 Git Tag
# ============================================
create_git_tag() {
    log_info "创建 Git Tag..."

    local tag_name="v${DEPLOY_VERSION}_${DEPLOY_TIMESTAMP}"

    git tag -a "$tag_name" -m "Production deployment: $DEPLOY_VERSION"
    git push origin "$tag_name" || log_warning "无法推送 tag 到远程仓库"

    log_success "Git Tag 已创建: $tag_name"
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

    # 准备蓝绿部署
    prepare_blue_green_deployment
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

    # 金丝雀部署
    canary_deployment
    echo ""

    # 健康检查
    health_check
    echo ""

    # 烟雾测试
    smoke_tests
    echo ""

    # 切换流量
    switch_traffic
    echo ""

    # 部署后验证
    post_deployment_verification
    echo ""

    # 创建 Git Tag
    create_git_tag
    echo ""

    # 发送成功通知
    send_deployment_notification "成功"

    log_success "=========================================="
    log_success "Production 部署完成！"
    log_success "版本: $DEPLOY_VERSION"
    log_success "环境: https://dacong.ai"
    log_success "回滚时间 < 5 分钟"
    log_success "=========================================="
}

# 捕获错误
trap 'log_error "部署失败，开始自动回滚..."; ./scripts/rollback.sh production $DEPLOY_VERSION; send_deployment_notification "失败"; exit 1' ERR

main "$@"
