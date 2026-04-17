#!/bin/bash
# Docker 健康检查脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_fail() {
    echo -e "${RED}✗${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# 检查服务健康状态
check_service() {
    local service=$1
    local status=$(docker-compose ps -q $service 2>/dev/null)

    if [ -z "$status" ]; then
        print_fail "$service: 未运行"
        return 1
    fi

    local health=$(docker inspect --format='{{.State.Health.Status}}' $(docker-compose ps -q $service) 2>/dev/null || echo "none")

    if [ "$health" = "healthy" ]; then
        print_success "$service: 健康"
        return 0
    elif [ "$health" = "none" ]; then
        print_warn "$service: 运行中（无健康检查）"
        return 0
    else
        print_fail "$service: 不健康 ($health)"
        return 1
    fi
}

# 检查端口
check_port() {
    local port=$1
    local name=$2

    if nc -z localhost $port 2>/dev/null; then
        print_success "$name (端口 $port): 可访问"
        return 0
    else
        print_fail "$name (端口 $port): 不可访问"
        return 1
    fi
}

# 检查 HTTP 端点
check_http() {
    local url=$1
    local name=$2

    if curl -sf "$url" > /dev/null; then
        print_success "$name: 响应正常"
        return 0
    else
        print_fail "$name: 无响应"
        return 1
    fi
}

echo "DaCong Docker 健康检查"
echo "====================="
echo ""

# 检查 Docker 服务
echo "检查 Docker 服务..."
check_service postgres
check_service redis
check_service api
check_service spider
check_service client
check_service admin
echo ""

# 检查端口
echo "检查端口..."
check_port 5432 "PostgreSQL"
check_port 6379 "Redis"
check_port 8000 "API"
check_port 80 "Client"
check_port 8080 "Admin"
echo ""

# 检查 HTTP 端点
echo "检查 HTTP 端点..."
check_http "http://localhost:8000/health" "API Health"
check_http "http://localhost/health" "Client Health"
check_http "http://localhost:8080/health" "Admin Health"
echo ""

# 检查资源使用
echo "资源使用情况..."
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
echo ""

# 检查磁盘使用
echo "磁盘使用情况..."
docker system df
echo ""

echo "健康检查完成"
