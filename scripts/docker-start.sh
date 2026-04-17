#!/bin/bash
# Docker 快速启动脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose 未安装，请先安装 Docker Compose"
        exit 1
    fi

    print_info "Docker 版本: $(docker --version)"
    print_info "Docker Compose 版本: $(docker-compose --version)"
}

# 检查环境变量文件
check_env() {
    if [ ! -f .env ]; then
        print_warn ".env 文件不存在，从模板创建..."
        cp .env.example .env
        print_warn "请编辑 .env 文件配置必要的环境变量"
        print_warn "必须配置: SUPABASE_URL, SUPABASE_ANON_KEY, ANTHROPIC_API_KEY"
        exit 1
    fi

    # 检查必需的环境变量
    source .env
    if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ] || [ -z "$ANTHROPIC_API_KEY" ]; then
        print_error "缺少必需的环境变量，请检查 .env 文件"
        exit 1
    fi

    print_info "环境变量配置正确"
}

# 构建镜像
build_images() {
    print_info "开始构建 Docker 镜像..."
    docker-compose build --parallel
    print_info "镜像构建完成"
}

# 启动服务
start_services() {
    print_info "启动所有服务..."
    docker-compose up -d
    print_info "服务启动完成"
}

# 等待服务就绪
wait_for_services() {
    print_info "等待服务就绪..."

    # 等待 PostgreSQL
    print_info "等待 PostgreSQL..."
    timeout 60 bash -c 'until docker-compose exec -T postgres pg_isready -U postgres; do sleep 2; done'

    # 等待 Redis
    print_info "等待 Redis..."
    timeout 30 bash -c 'until docker-compose exec -T redis redis-cli ping; do sleep 2; done'

    # 等待 API
    print_info "等待 API..."
    timeout 60 bash -c 'until curl -sf http://localhost:8000/health > /dev/null; do sleep 2; done'

    print_info "所有服务已就绪"
}

# 显示服务状态
show_status() {
    print_info "服务状态:"
    docker-compose ps

    echo ""
    print_info "访问地址:"
    echo "  客户端:     http://localhost"
    echo "  管理后台:   http://localhost:8080"
    echo "  API:        http://localhost:8000"
    echo "  PostgreSQL: localhost:5432"
    echo "  Redis:      localhost:6379"

    echo ""
    print_info "查看日志: docker-compose logs -f"
    print_info "停止服务: docker-compose down"
}

# 主函数
main() {
    print_info "DaCong Docker 快速启动脚本"
    echo ""

    check_docker
    check_env
    build_images
    start_services
    wait_for_services
    show_status

    print_info "部署完成！"
}

# 执行主函数
main
