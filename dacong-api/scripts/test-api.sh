#!/bin/bash

# API 测试脚本
# 用于测试 get-recommendations API 的各种场景

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# API 基础 URL（根据实际部署修改）
BASE_URL="${API_BASE_URL:-http://localhost:54321/functions/v1}"
API_ENDPOINT="${BASE_URL}/get-recommendations"

echo "=========================================="
echo "推荐 API 测试脚本"
echo "=========================================="
echo ""

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
test_api() {
  local test_name=$1
  local url=$2
  local expected_status=${3:-200}

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  echo -e "${YELLOW}测试 ${TOTAL_TESTS}: ${test_name}${NC}"
  echo "URL: ${url}"

  # 发送请求
  response=$(curl -s -w "\n%{http_code}" "${url}")
  http_code=$(echo "$response" | tail -n1)
  body=$(echo "$response" | sed '$d')

  # 检查状态码
  if [ "$http_code" -eq "$expected_status" ]; then
    echo -e "${GREEN}✓ 状态码正确: ${http_code}${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ 状态码错误: 期望 ${expected_status}, 实际 ${http_code}${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

  # 美化输出 JSON
  if command -v jq &> /dev/null; then
    echo "响应内容:"
    echo "$body" | jq '.'
  else
    echo "响应内容:"
    echo "$body"
  fi

  echo ""
  echo "----------------------------------------"
  echo ""
}

# 测试 1: 获取 coding 场景推荐（中文）
test_api \
  "获取 coding 场景推荐（中文）" \
  "${API_ENDPOINT}?scenario=coding&language=zh&limit=10" \
  200

# 测试 2: 获取 video 场景推荐（英文）
test_api \
  "获取 video 场景推荐（英文）" \
  "${API_ENDPOINT}?scenario=video&language=en&limit=5" \
  200

# 测试 3: 获取 image 场景推荐（默认参数）
test_api \
  "获取 image 场景推荐（默认参数）" \
  "${API_ENDPOINT}?scenario=image" \
  200

# 测试 4: 获取 chat 场景推荐
test_api \
  "获取 chat 场景推荐" \
  "${API_ENDPOINT}?scenario=chat&limit=20" \
  200

# 测试 5: 获取 writing 场景推荐
test_api \
  "获取 writing 场景推荐" \
  "${API_ENDPOINT}?scenario=writing&limit=15" \
  200

# 测试 6: 获取 data 场景推荐
test_api \
  "获取 data 场景推荐" \
  "${API_ENDPOINT}?scenario=data&limit=10" \
  200

# 测试 7: 缺少必需参数（应该返回 400）
test_api \
  "缺少必需参数 scenario" \
  "${API_ENDPOINT}?language=zh" \
  400

# 测试 8: 无效的 scenario（应该返回 400）
test_api \
  "无效的 scenario 参数" \
  "${API_ENDPOINT}?scenario=invalid&language=zh" \
  400

# 测试 9: 无效的 language（应该返回 400）
test_api \
  "无效的 language 参数" \
  "${API_ENDPOINT}?scenario=coding&language=fr" \
  400

# 测试 10: 超出范围的 limit（应该返回 400）
test_api \
  "超出范围的 limit 参数" \
  "${API_ENDPOINT}?scenario=coding&limit=100" \
  400

# 测试 11: 负数 limit（应该返回 400）
test_api \
  "负数 limit 参数" \
  "${API_ENDPOINT}?scenario=coding&limit=-1" \
  400

# 测试 12: 测试缓存（连续两次相同请求）
echo -e "${YELLOW}测试 12: 测试缓存机制${NC}"
echo "第一次请求（应该查询数据库）..."
time curl -s "${API_ENDPOINT}?scenario=coding&limit=10" > /dev/null
echo ""
echo "第二次请求（应该从缓存获取，更快）..."
time curl -s "${API_ENDPOINT}?scenario=coding&limit=10" > /dev/null
echo ""
echo "----------------------------------------"
echo ""

# 测试 13: 性能测试（响应时间）
echo -e "${YELLOW}测试 13: 性能测试（10次请求平均响应时间）${NC}"
total_time=0
iterations=10

for i in $(seq 1 $iterations); do
  start_time=$(date +%s%N)
  curl -s "${API_ENDPOINT}?scenario=coding&limit=10" > /dev/null
  end_time=$(date +%s%N)

  elapsed=$((($end_time - $start_time) / 1000000)) # 转换为毫秒
  total_time=$(($total_time + $elapsed))

  echo "请求 $i: ${elapsed}ms"
done

avg_time=$(($total_time / $iterations))
echo ""
echo "平均响应时间: ${avg_time}ms"

if [ $avg_time -lt 200 ]; then
  echo -e "${GREEN}✓ 性能测试通过（< 200ms）${NC}"
  PASSED_TESTS=$((PASSED_TESTS + 1))
else
  echo -e "${RED}✗ 性能测试失败（>= 200ms）${NC}"
  FAILED_TESTS=$((FAILED_TESTS + 1))
fi

TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo ""
echo "----------------------------------------"
echo ""

# 测试总结
echo "=========================================="
echo "测试总结"
echo "=========================================="
echo "总测试数: ${TOTAL_TESTS}"
echo -e "${GREEN}通过: ${PASSED_TESTS}${NC}"
echo -e "${RED}失败: ${FAILED_TESTS}${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
  echo -e "${GREEN}所有测试通过！🎉${NC}"
  exit 0
else
  echo -e "${RED}部分测试失败，请检查日志${NC}"
  exit 1
fi
