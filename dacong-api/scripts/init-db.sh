#!/bin/bash

# Supabase 数据库初始化脚本
# 用途：检查环境、初始化项目、运行 migrations

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Supabase CLI 是否安装
check_supabase_cli() {
    log_info "检查 Supabase CLI..."

    if ! command -v supabase &> /dev/null; then
        log_error "Supabase CLI 未安装"
        echo ""
        echo "请安装 Supabase CLI："
        echo "  macOS:   brew install supabase/tap/supabase"
        echo "  Windows: scoop bucket add supabase https://github.com/supabase/scoop-bucket.git"
        echo "           scoop install supabase"
        echo "  Linux:   参考 https://supabase.com/docs/guides/cli"
        exit 1
    fi

    log_info "Supabase CLI 已安装: $(supabase --version)"
}

# 检查 .env 文件
check_env_file() {
    log_info "检查环境变量配置..."

    if [ ! -f ".env" ]; then
        log_warn ".env 文件不存在，从 .env.example 复制"

        if [ -f ".env.example" ]; then
            cp .env.example .env
            log_info "已创建 .env 文件，请填写 Supabase 配置"
            echo ""
            echo "需要配置的变量："
            echo "  SUPABASE_URL=your-project-url"
            echo "  SUPABASE_ANON_KEY=your-anon-key"
            echo "  SUPABASE_SERVICE_ROLE_KEY=your-service-role-key"
            echo ""
            read -p "是否现在配置？(y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                ${EDITOR:-nano} .env
            else
                log_error "请先配置 .env 文件后再运行此脚本"
                exit 1
            fi
        else
            log_error ".env.example 文件不存在"
            exit 1
        fi
    fi

    # 加载环境变量
    source .env

    # 检查必需的环境变量
    if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
        log_error "缺少必需的环境变量，请检查 .env 文件"
        exit 1
    fi

    log_info "环境变量配置正确"
}

# 初始化 Supabase 项目
init_supabase_project() {
    log_info "初始化 Supabase 项目..."

    if [ -f "supabase/config.toml" ]; then
        log_warn "Supabase 项目已初始化，跳过"
        return
    fi

    supabase init
    log_info "Supabase 项目初始化完成"
}

# 链接到远程项目
link_remote_project() {
    log_info "链接到远程 Supabase 项目..."

    # 从 SUPABASE_URL 提取项目 ID
    # 格式: https://xxxxx.supabase.co
    PROJECT_REF=$(echo $SUPABASE_URL | sed -E 's|https://([^.]+)\.supabase\.co|\1|')

    if [ -z "$PROJECT_REF" ]; then
        log_error "无法从 SUPABASE_URL 提取项目 ID"
        exit 1
    fi

    log_info "项目 ID: $PROJECT_REF"

    # 检查是否已链接
    if supabase status &> /dev/null; then
        log_warn "已链接到远程项目，跳过"
        return
    fi

    # 链接项目
    supabase link --project-ref $PROJECT_REF
    log_info "成功链接到远程项目"
}

# 运行 migrations
run_migrations() {
    log_info "运行数据库 migrations..."

    # 检查 migrations 目录
    if [ ! -d "supabase/migrations" ]; then
        log_error "migrations 目录不存在"
        exit 1
    fi

    # 统计 migration 文件数量
    MIGRATION_COUNT=$(ls -1 supabase/migrations/*.sql 2>/dev/null | wc -l)

    if [ $MIGRATION_COUNT -eq 0 ]; then
        log_warn "没有找到 migration 文件"
        return
    fi

    log_info "找到 $MIGRATION_COUNT 个 migration 文件"

    # 推送 migrations 到远程
    supabase db push

    log_info "Migrations 运行完成"
}

# 验证表结构
verify_tables() {
    log_info "验证数据库表结构..."

    # 期望的表列表
    EXPECTED_TABLES=(
        "raw_data"
        "generated_content"
        "published_content"
        "user_feedback"
        "scenario_recommendations"
        "spider_logs"
    )

    log_info "检查表是否存在..."

    for table in "${EXPECTED_TABLES[@]}"; do
        # 使用 Supabase CLI 查询表
        if supabase db execute "SELECT to_regclass('public.$table');" | grep -q "$table"; then
            log_info "✓ 表 $table 存在"
        else
            log_error "✗ 表 $table 不存在"
            exit 1
        fi
    done

    log_info "所有表验证通过"
}

# 显示数据库信息
show_db_info() {
    log_info "数据库信息："
    echo ""
    echo "  项目 URL: $SUPABASE_URL"
    echo "  数据库状态: $(supabase status 2>/dev/null | grep 'DB URL' || echo '未连接')"
    echo ""
    log_info "可用的视图："
    echo "  - content_stats (内容统计)"
    echo "  - review_queue (待审核队列)"
    echo "  - spider_stats (爬虫统计)"
    echo ""
}

# 主函数
main() {
    echo ""
    log_info "=========================================="
    log_info "  Supabase 数据库初始化脚本"
    log_info "=========================================="
    echo ""

    # 切换到项目根目录
    cd "$(dirname "$0")/.."

    # 执行检查和初始化
    check_supabase_cli
    check_env_file
    init_supabase_project
    link_remote_project
    run_migrations
    verify_tables
    show_db_info

    echo ""
    log_info "=========================================="
    log_info "  数据库初始化完成！"
    log_info "=========================================="
    echo ""

    log_info "下一步："
    echo "  1. 运行爬虫采集数据: cd ../dacong-spider && python main.py"
    echo "  2. 启动 API 服务: npm run dev"
    echo "  3. 查看 Supabase Dashboard: supabase dashboard"
    echo ""
}

# 运行主函数
main "$@"
