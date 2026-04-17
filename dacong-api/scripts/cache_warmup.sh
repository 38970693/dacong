#!/bin/bash
# Redis 缓存预热脚本
# 用于在系统启动时预加载热点数据到 Redis

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
API_BASE_URL="${API_BASE_URL:-http://localhost:8000}"
REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"

echo -e "${GREEN}=== Redis 缓存预热开始 ===${NC}"
echo "API URL: $API_BASE_URL"
echo "Redis: $REDIS_HOST:$REDIS_PORT"
echo ""

# 检查 Redis 连接
echo -e "${YELLOW}[1/5] 检查 Redis 连接...${NC}"
if redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Redis 连接正常${NC}"
else
    echo -e "${RED}✗ Redis 连接失败${NC}"
    exit 1
fi

# 检查 API 健康状态
echo -e "${YELLOW}[2/5] 检查 API 健康状态...${NC}"
if curl -sf "$API_BASE_URL/health" > /dev/null; then
    echo -e "${GREEN}✓ API 服务正常${NC}"
else
    echo -e "${RED}✗ API 服务不可用${NC}"
    exit 1
fi

# 预热热门内容
echo -e "${YELLOW}[3/5] 预热热门内容...${NC}"
curl -sf "$API_BASE_URL/api/v1/content/hot?limit=50" > /dev/null && \
    echo -e "${GREEN}✓ 热门内容已缓存${NC}" || \
    echo -e "${RED}✗ 热门内容缓存失败${NC}"

# 预热推荐内容
echo -e "${YELLOW}[4/5] 预热推荐内容...${NC}"
curl -sf "$API_BASE_URL/api/v1/recommendations?limit=20" > /dev/null && \
    echo -e "${GREEN}✓ 推荐内容已缓存${NC}" || \
    echo -e "${RED}✗ 推荐内容缓存失败${NC}"

# 预热趋势数据
echo -e "${YELLOW}[5/5] 预热趋势数据...${NC}"
curl -sf "$API_BASE_URL/api/v1/analytics/trends?period=7d" > /dev/null && \
    echo -e "${GREEN}✓ 趋势数据已缓存${NC}" || \
    echo -e "${RED}✗ 趋势数据缓存失败${NC}"

# 显示缓存统计
echo ""
echo -e "${GREEN}=== 缓存统计 ===${NC}"
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" INFO stats | grep -E "keyspace_hits|keyspace_misses"
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" DBSIZE

echo ""
echo -e "${GREEN}=== 缓存预热完成 ===${NC}"
