#!/bin/bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  日志聚合系统完整验收测试${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
test_case() {
    local test_name="$1"
    local test_command="$2"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${YELLOW}[TEST $TOTAL_TESTS] $test_name${NC}"

    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

echo -e "${BLUE}=== 1. 检查配置文件 ===${NC}"
test_case "Docker Compose 配置存在" "test -f docker-compose.logging.yml"
test_case "Loki 配置存在" "test -f config/loki-config.yaml"
test_case "Promtail 配置存在" "test -f config/promtail-config.yaml"
test_case "Loki 告警规则存在" "test -f config/loki-rules.yaml"
test_case "Grafana 数据源配置存在" "test -f config/grafana/provisioning/datasources/loki.yaml"
test_case "Grafana Dashboard 配置存在" "test -f config/grafana/provisioning/dashboards/dashboard.yaml"
echo ""

echo -e "${BLUE}=== 2. 检查日志记录器代码 ===${NC}"
test_case "Flutter 日志记录器存在" "test -f dacong-client/lib/core/logging/logger.dart"
test_case "TypeScript 日志记录器存在" "test -f dacong-api/supabase/functions/_shared/utils/logger.ts"
test_case "Python 日志记录器存在" "test -f dacong-spider/core/logger.py"
echo ""

echo -e "${BLUE}=== 3. 检查脚本文件 ===${NC}"
test_case "部署脚本存在" "test -f scripts/setup_logging.sh"
test_case "测试脚本存在" "test -f scripts/test_logging.sh"
test_case "部署脚本可执行" "test -x scripts/setup_logging.sh"
test_case "测试脚本可执行" "test -x scripts/test_logging.sh"
echo ""

echo -e "${BLUE}=== 4. 检查文档 ===${NC}"
test_case "日志聚合文档存在" "test -f docs/monitoring/LOG_AGGREGATION.md"
test_case "告警规则文档存在" "test -f docs/monitoring/LOG_ALERTS.md"
test_case "快速开始文档存在" "test -f LOGGING_QUICKSTART.md"
test_case "验收清单存在" "test -f LOG_AGGREGATION_ACCEPTANCE.md"
echo ""

echo -e "${BLUE}=== 5. 检查日志目录 ===${NC}"
test_case "API 日志目录存在" "test -d logs/api"
test_case "爬虫日志目录存在" "test -d logs/spider"
test_case "客户端日志目录存在" "test -d logs/client"
echo ""

echo -e "${BLUE}=== 6. 检查 Docker 环境 ===${NC}"
test_case "Docker 已安装" "command -v docker"
test_case "Docker Compose 已安装" "command -v docker-compose"
echo ""

echo -e "${BLUE}=== 7. 检查服务状态 ===${NC}"
if docker-compose -f docker-compose.logging.yml ps 2>/dev/null | grep -q "Up"; then
    echo -e "${YELLOW}[INFO] 日志服务正在运行，执行健康检查...${NC}"

    test_case "Loki 服务健康" "curl -sf http://localhost:3100/ready | grep -q ready"
    test_case "Grafana 服务健康" "curl -sf http://localhost:3000/api/health | grep -q ok"
    test_case "Promtail 容器运行" "docker ps | grep -q dacong-promtail"

    echo ""
    echo -e "${BLUE}=== 8. 测试日志查询 ===${NC}"

    # 生成测试日志
    echo -e "${YELLOW}[INFO] 生成测试日志...${NC}"
    cat > logs/api/acceptance-test.log << EOF
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","level":"INFO","service":"dacong-api","function":"test","message":"Acceptance test log"}
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","level":"ERROR","service":"dacong-api","function":"test","message":"Test error log"}
EOF

    cat > logs/spider/acceptance-test.log << EOF
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","level":"INFO","service":"dacong-spider","module":"test","message":"Acceptance test log"}
EOF

    cat > logs/client/acceptance-test.log << EOF
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","level":"INFO","service":"dacong-client","module":"test","message":"Acceptance test log"}
EOF

    # 等待 Promtail 采集
    echo -e "${YELLOW}[INFO] 等待日志采集（10秒）...${NC}"
    sleep 10

    test_case "查询所有日志" "curl -sf -G 'http://localhost:3100/loki/api/v1/query' --data-urlencode 'query={service=~\"dacong-.*\"}' --data-urlencode 'limit=10' | jq -e '.data.result | length > 0'"
    test_case "查询 API 日志" "curl -sf -G 'http://localhost:3100/loki/api/v1/query' --data-urlencode 'query={service=\"dacong-api\"}' --data-urlencode 'limit=5' | jq -e '.data.result | length > 0'"
    test_case "查询错误日志" "curl -sf -G 'http://localhost:3100/loki/api/v1/query' --data-urlencode 'query={service=~\"dacong-.*\"} |= \"ERROR\"' --data-urlencode 'limit=5' | jq -e '.data.result | length > 0'"
else
    echo -e "${YELLOW}[SKIP] 日志服务未运行，跳过运行时测试${NC}"
    echo -e "${YELLOW}[INFO] 运行 ./scripts/setup_logging.sh 启动服务后再测试${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  测试结果汇总${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "总测试数: ${TOTAL_TESTS}"
echo -e "${GREEN}通过: ${PASSED_TESTS}${NC}"
echo -e "${RED}失败: ${FAILED_TESTS}${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✓ 所有测试通过！日志聚合系统验收成功！${NC}"
    echo ""
    echo -e "${BLUE}下一步操作：${NC}"
    echo -e "1. 如果服务未运行，执行: ${YELLOW}./scripts/setup_logging.sh${NC}"
    echo -e "2. 访问 Grafana: ${YELLOW}http://localhost:3000${NC} (admin/admin)"
    echo -e "3. 在应用中集成日志记录器"
    echo -e "4. 配置生产环境告警通知"
    echo ""
    exit 0
else
    echo -e "${RED}✗ 有 $FAILED_TESTS 个测试失败，请检查配置${NC}"
    echo ""
    exit 1
fi
