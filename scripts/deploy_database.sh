#!/bin/bash

# ============================================
# 数据库部署脚本
# ============================================
# 用途：部署数据库 schema 和 migrations
# 使用：./scripts/deploy_database.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 获取项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT/dacong-api"

# 检查 Supabase CLI
if ! command -v supabase &> /dev/null; then
    log_error "Supabase CLI 未安装"
    exit 1
fi

# 加载环境变量
if [ -f "../.env.test.local" ]; then
    set -a
    source ../.env.test.local
    set +a
fi

log_info "开始部署数据库..."

# ============================================
# 1. 检查数据库连接
# ============================================
log_info "检查数据库连接..."

if [ -z "$SUPABASE_URL" ]; then
    log_error "SUPABASE_URL 未设置"
    exit 1
fi

# 提取项目 ID
PROJECT_ID=$(echo "$SUPABASE_URL" | sed -n 's/.*\/\/\([^.]*\).*/\1/p')

if [ -z "$PROJECT_ID" ]; then
    log_error "无法从 SUPABASE_URL 提取项目 ID"
    exit 1
fi

log_info "项目 ID: $PROJECT_ID"

# ============================================
# 2. 链接到 Supabase 项目
# ============================================
log_info "链接到 Supabase 项目..."

# 检查是否已链接
if [ ! -f ".supabase/config.toml" ]; then
    log_info "首次部署，需要链接项目..."
    supabase link --project-ref "$PROJECT_ID"
fi

# ============================================
# 3. 运行数据库迁移
# ============================================
log_info "运行数据库迁移..."

# 检查是否有待执行的迁移
PENDING_MIGRATIONS=$(supabase db diff --schema public 2>&1 || true)

if [ -n "$PENDING_MIGRATIONS" ]; then
    log_info "发现待执行的迁移"

    # 推送迁移到远程数据库
    supabase db push

    log_success "迁移执行完成"
else
    log_info "没有待执行的迁移"
fi

# ============================================
# 4. 验证数据库 schema
# ============================================
log_info "验证数据库 schema..."

# 检查关键表是否存在
TABLES=(
    "raw_data"
    "generated_content"
    "published_content"
    "user_feedback"
    "scenario_recommendations"
    "comments"
    "comment_likes"
    "comment_reports"
)

for table in "${TABLES[@]}"; do
    if supabase db execute "SELECT 1 FROM $table LIMIT 1" &> /dev/null; then
        log_success "表 $table 存在"
    else
        log_error "表 $table 不存在"
        exit 1
    fi
done

# ============================================
# 5. 初始化测试数据（可选）
# ============================================
if [ "$INIT_TEST_DATA" = "true" ]; then
    log_info "初始化测试数据..."

    if [ -f "scripts/init_test_data.sql" ]; then
        supabase db execute < scripts/init_test_data.sql
        log_success "测试数据初始化完成"
    else
        log_warning "测试数据脚本不存在: scripts/init_test_data.sql"
    fi
fi

# ============================================
# 6. 生成类型定义（可选）
# ============================================
if command -v supabase &> /dev/null; then
    log_info "生成 TypeScript 类型定义..."
    supabase gen types typescript --local > types/database.types.ts 2>/dev/null || true
fi

log_success "数据库部署完成"

# 输出数据库信息
echo ""
log_info "数据库信息:"
log_info "  URL: $SUPABASE_URL"
log_info "  项目 ID: $PROJECT_ID"
log_info "  迁移文件: supabase/migrations/"
echo ""
