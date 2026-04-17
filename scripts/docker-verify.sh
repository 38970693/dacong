#!/bin/bash
# Docker 快速验证脚本

set -e

echo "DaCong Docker 配置验证"
echo "====================="
echo ""

# 检查文件是否存在
check_file() {
    if [ -f "$1" ]; then
        echo "✓ $1"
    else
        echo "✗ $1 (缺失)"
        return 1
    fi
}

echo "检查 Dockerfile..."
check_file "dacong-api/Dockerfile"
check_file "dacong-spider/Dockerfile"
check_file "dacong-client/Dockerfile"
check_file "dacong-admin/Dockerfile"
echo ""

echo "检查 .dockerignore..."
check_file "dacong-api/.dockerignore"
check_file "dacong-spider/.dockerignore"
check_file "dacong-client/.dockerignore"
check_file "dacong-admin/.dockerignore"
check_file ".dockerignore"
echo ""

echo "检查 Nginx 配置..."
check_file "dacong-client/nginx.conf"
check_file "dacong-admin/nginx.conf"
echo ""

echo "检查 Docker Compose..."
check_file "docker-compose.yml"
check_file "docker-compose.dev.yml"
check_file ".env.example"
echo ""

echo "检查脚本..."
check_file "scripts/docker-start.sh"
check_file "scripts/docker-health-check.sh"
echo ""

echo "检查文档..."
check_file "dacong-docs/deployment/DOCKER_DEPLOYMENT.md"
echo ""

# 验证 docker-compose.yml 语法
echo "验证 docker-compose.yml 语法..."
if docker-compose config > /dev/null 2>&1; then
    echo "✓ docker-compose.yml 语法正确"
else
    echo "✗ docker-compose.yml 语法错误"
    docker-compose config
    exit 1
fi
echo ""

# 检查镜像大小估算
echo "镜像大小估算:"
echo "  dacong-api:      ~150MB (Deno Alpine)"
echo "  dacong-spider:   ~200MB (Python slim)"
echo "  dacong-client:   ~50MB  (Nginx Alpine)"
echo "  dacong-admin:    ~50MB  (Nginx Alpine)"
echo "  postgres:        ~80MB  (PostgreSQL Alpine)"
echo "  redis:           ~30MB  (Redis Alpine)"
echo "  --------------------------------"
echo "  总计:            ~560MB"
echo ""

echo "验证完成！"
echo ""
echo "下一步:"
echo "  1. 复制环境变量: cp .env.example .env"
echo "  2. 编辑 .env 配置必需的环境变量"
echo "  3. 启动服务: ./scripts/docker-start.sh"
echo "  4. 健康检查: ./scripts/docker-health-check.sh"
