#!/bin/bash

# ============================================
# DaCong 测试环境部署脚本
# ============================================
# 用途: 自动化部署到测试环境
# 使用: ./scripts/deploy_test.sh

set -e  # 遇到错误立即退出
set -u  # 使用未定义变量时报错

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# ============================================
# 步骤 1: 环境检查
# ============================================
check_environment() {
    log_info "检查部署环境..."

    # 检查必需的命令
    local required_commands=("supabase" "psql" "flutter" "jq" "curl")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "缺少必需命令: $cmd"
            log_info "请安装: $cmd"
            exit 1
        fi
    done

    # 检查 .env.test 文件
    if [ ! -f "$PROJECT_ROOT/.env.test" ]; then
        log_error "缺少 .env.test 文件"
        log_info "请从 .env.test.example 复制并配置"
        exit 1
    fi

    # 加载环境变量
    set -a
    source "$PROJECT_ROOT/.env.test"
    set +a

    # 验证必需的环境变量
    local required_vars=("SUPABASE_URL" "SUPABASE_SERVICE_ROLE_KEY" "DATABASE_URL")
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            log_error "缺少环境变量: $var"
            exit 1
        fi
    done

    log_success "环境检查通过"
}

# ============================================
# 步骤 2: 部署数据库
# ============================================
deploy_database() {
    log_info "部署数据库..."

    cd "$PROJECT_ROOT/dacong-api"

    # 检查 Supabase 连接
    log_info "测试数据库连接..."
    if ! psql "$DATABASE_URL" -c "SELECT 1" &> /dev/null; then
        log_error "无法连接到数据库"
        exit 1
    fi

    # 运行 migrations
    log_info "运行数据库迁移..."
    local migration_dir="$PROJECT_ROOT/dacong-api/supabase/migrations"

    for migration in "$migration_dir"/*.sql; do
        if [ -f "$migration" ]; then
            log_info "执行: $(basename "$migration")"
            psql "$DATABASE_URL" -f "$migration" || {
                log_error "迁移失败: $(basename "$migration")"
                exit 1
            }
        fi
    done

    # 初始化测试数据
    if [ -f "$PROJECT_ROOT/scripts/init_test_data.sql" ]; then
        log_info "初始化测试数据..."
        psql "$DATABASE_URL" -f "$PROJECT_ROOT/scripts/init_test_data.sql"
    fi

    log_success "数据库部署完成"
}

# ============================================
# 步骤 3: 部署 Edge Functions
# ============================================
deploy_functions() {
    log_info "部署 Edge Functions..."

    cd "$PROJECT_ROOT/dacong-api"

    # 获取所有 function 目录
    local functions_dir="$PROJECT_ROOT/dacong-api/supabase/functions"
    local functions=(
        "get-recommendations"
        "search-content"
        "get-content-detail"
        "get-weekly-report"
        "submit-feedback"
        "compute-ranks"
        "content-moderation"
    )

    for func in "${functions[@]}"; do
        if [ -d "$functions_dir/$func" ]; then
            log_info "部署函数: $func"
            supabase functions deploy "$func" --project-ref "${SUPABASE_URL##*//}" || {
                log_warning "函数部署失败: $func (继续部署其他函数)"
            }
        else
            log_warning "函数目录不存在: $func"
        fi
    done

    log_success "Edge Functions 部署完成"
}

# ============================================
# 步骤 4: 构建前端
# ============================================
build_frontend() {
    log_info "构建前端..."

    cd "$PROJECT_ROOT/dacong-client"

    # 清理旧构建
    if [ -d "build/web" ]; then
        rm -rf build/web
    fi

    # 安装依赖
    log_info "安装 Flutter 依赖..."
    flutter pub get

    # 构建 Web 版本
    log_info "构建 Flutter Web..."
    flutter build web --release --dart-define=ENVIRONMENT=test

    # 打包构建产物
    log_info "打包构建产物..."
    cd build
    tar -czf web.tar.gz web/

    log_success "前端构建完成: dacong-client/build/web.tar.gz"
}

# ============================================
# 步骤 5: 部署前端（可选）
# ============================================
deploy_frontend() {
    log_info "部署前端..."

    # 这里可以添加部署到 Vercel/Netlify/Cloudflare Pages 的逻辑
    # 示例: vercel deploy --prod

    log_warning "前端部署需要手动执行或配置 CI/CD"
    log_info "构建产物位于: dacong-client/build/web/"
}

# ============================================
# 步骤 6: 健康检查
# ============================================
health_check() {
    log_info "执行健康检查..."

    if [ -f "$PROJECT_ROOT/scripts/health_check.sh" ]; then
        bash "$PROJECT_ROOT/scripts/health_check.sh"
    else
        log_warning "健康检查脚本不存在，跳过"
    fi
}

# ============================================
# 步骤 7: 运行验证测试
# ============================================
run_verification() {
    log_info "运行验证测试..."

    if [ -f "$PROJECT_ROOT/scripts/verify_deployment.sh" ]; then
        bash "$PROJECT_ROOT/scripts/verify_deployment.sh"
    else
        log_warning "验证脚本不存在，跳过"
    fi
}

# ============================================
# 主流程
# ============================================
main() {
    log_info "=========================================="
    log_info "DaCong 测试环境部署"
    log_info "=========================================="
    log_info "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    # 执行部署步骤
    check_environment
    echo ""

    deploy_database
    echo ""

    deploy_functions
    echo ""

    build_frontend
    echo ""

    deploy_frontend
    echo ""

    health_check
    echo ""

    run_verification
    echo ""

    # 部署完成
    log_info "=========================================="
    log_success "部署完成！"
    log_info "=========================================="
    log_info "结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
    log_info ""
    log_info "下一步:"
    log_info "  1. 访问前端: ${FRONTEND_URL:-http://localhost:3000}"
    log_info "  2. 查看 API 文档: ${SUPABASE_URL}/functions/v1"
    log_info "  3. 查看数据库: Supabase Dashboard"
    log_info ""
    log_info "如需回滚，运行: ./scripts/rollback.sh"
}

# 捕获错误
trap 'log_error "部署失败，请检查错误信息"; exit 1' ERR

# 运行主流程
main "$@"
