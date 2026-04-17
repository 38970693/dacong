#!/bin/bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== 大聪日志聚合系统部署脚本 ===${NC}"

# 检查 Docker 和 Docker Compose
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}错误: Docker Compose 未安装${NC}"
    exit 1
fi

# 创建日志目录
echo -e "${YELLOW}创建日志目录...${NC}"
mkdir -p logs/{api,spider,client}
mkdir -p config/grafana/provisioning/{datasources,dashboards}

# 设置权限
chmod -R 755 logs/
chmod -R 755 config/

# 检查配置文件
echo -e "${YELLOW}检查配置文件...${NC}"
required_files=(
    "docker-compose.logging.yml"
    "config/loki-config.yaml"
    "config/promtail-config.yaml"
    "config/grafana/provisioning/datasources/loki.yaml"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}错误: 配置文件 $file 不存在${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ $file${NC}"
done

# 停止现有容器
echo -e "${YELLOW}停止现有日志服务...${NC}"
docker-compose -f docker-compose.logging.yml down 2>/dev/null || true

# 启动日志聚合服务
echo -e "${YELLOW}启动日志聚合服务...${NC}"
docker-compose -f docker-compose.logging.yml up -d

# 等待服务启动
echo -e "${YELLOW}等待服务启动...${NC}"
sleep 10

# 健康检查
echo -e "${YELLOW}执行健康检查...${NC}"

# 检查 Loki
if curl -s http://localhost:3100/ready | grep -q "ready"; then
    echo -e "${GREEN}✓ Loki 运行正常${NC}"
else
    echo -e "${RED}✗ Loki 启动失败${NC}"
    docker-compose -f docker-compose.logging.yml logs loki
    exit 1
fi

# 检查 Grafana
if curl -s http://localhost:3000/api/health | grep -q "ok"; then
    echo -e "${GREEN}✓ Grafana 运行正常${NC}"
else
    echo -e "${RED}✗ Grafana 启动失败${NC}"
    docker-compose -f docker-compose.logging.yml logs grafana
    exit 1
fi

# 检查 Promtail
if docker ps | grep -q dacong-promtail; then
    echo -e "${GREEN}✓ Promtail 运行正常${NC}"
else
    echo -e "${RED}✗ Promtail 启动失败${NC}"
    docker-compose -f docker-compose.logging.yml logs promtail
    exit 1
fi

# 显示访问信息
echo -e "\n${GREEN}=== 日志聚合系统部署成功 ===${NC}"
echo -e "\n访问信息:"
echo -e "  Grafana: ${GREEN}http://localhost:3000${NC}"
echo -e "  默认账号: ${YELLOW}admin${NC}"
echo -e "  默认密码: ${YELLOW}admin${NC} (首次登录后需修改)"
echo -e "  Loki API: ${GREEN}http://localhost:3100${NC}"
echo -e "\n日志目录:"
echo -e "  API 日志: ${YELLOW}./logs/api/${NC}"
echo -e "  爬虫日志: ${YELLOW}./logs/spider/${NC}"
echo -e "  客户端日志: ${YELLOW}./logs/client/${NC}"
echo -e "\n常用命令:"
echo -e "  查看日志: ${YELLOW}docker-compose -f docker-compose.logging.yml logs -f${NC}"
echo -e "  停止服务: ${YELLOW}docker-compose -f docker-compose.logging.yml down${NC}"
echo -e "  重启服务: ${YELLOW}docker-compose -f docker-compose.logging.yml restart${NC}"
echo -e "\n下一步:"
echo -e "  1. 访问 Grafana 并修改默认密码"
echo -e "  2. 配置应用程序日志输出到 ./logs/ 目录"
echo -e "  3. 在 Grafana 中创建日志查询面板"
echo -e "  4. 配置告警规则"
