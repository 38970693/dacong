#!/bin/bash

# SQL 注入防护测试脚本
# 测试 API 是否能够防御 SQL 注入攻击

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
API_BASE_URL="${API_BASE_URL:-http://localhost:54321/functions/v1}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"

if [ -z "$SUPABASE_ANON_KEY" ]; then
  echo -e "${RED}Error: SUPABASE_ANON_KEY environment variable is not set${NC}"
  exit 1
fi

echo "=========================================="
echo "SQL 注入防护测试"
echo "=========================================="
echo ""

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
test_sql_injection() {
  local test_name="$1"
  local endpoint="$2"
  local payload="$3"
  local method="${4:-POST}"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  echo -e "${YELLOW}测试 $TOTAL_TESTS: $test_name${NC}"

  local response
  local http_code

  if [ "$method" = "POST" ]; then
    response=$(curl -s -w "\n%{http_code}" \
      -X POST \
      -H "Content-Type: application/json" \
      -H "apikey: $SUPABASE_ANON_KEY" \
      -d "$payload" \
      "$API_BASE_URL/$endpoint")
  else
    response=$(curl -s -w "\n%{http_code}" \
      -X GET \
      -H "apikey: $SUPABASE_ANON_KEY" \
      "$API_BASE_URL/$endpoint?$payload")
  fi

  http_code=$(echo "$response" | tail -n1)
  body=$(echo "$response" | head -n-1)

  # 检查是否返回 400 错误（验证失败）
  if [ "$http_code" = "400" ]; then
    echo -e "${GREEN}✓ 通过 - API 正确拒绝了恶意输入 (HTTP $http_code)${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  else
    echo -e "${RED}✗ 失败 - API 未能拒绝恶意输入 (HTTP $http_code)${NC}"
    echo "响应: $body"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi

  echo ""
}

# 测试 1: 搜索内容 - SQL 注入尝试
test_sql_injection \
  "搜索内容 - SQL 注入 (UNION SELECT)" \
  "search-content" \
  "query=' OR '1'='1' UNION SELECT * FROM users--" \
  "GET"

# 测试 2: 搜索内容 - SQL 注入尝试 (DROP TABLE)
test_sql_injection \
  "搜索内容 - SQL 注入 (DROP TABLE)" \
  "search-content" \
  "query='; DROP TABLE published_content;--" \
  "GET"

# 测试 3: 提交评论 - SQL 注入尝试
test_sql_injection \
  "提交评论 - SQL 注入 (content_id)" \
  "submit-comment" \
  '{"content_id": "'\'' OR 1=1--", "content": "test comment"}'

# 测试 4: 提交评论 - SQL 注入尝试 (content)
test_sql_injection \
  "提交评论 - SQL 注入 (content)" \
  "submit-comment" \
  '{"content_id": "550e8400-e29b-41d4-a716-446655440000", "content": "test'\'' OR '\''1'\''='\''1"}'

# 测试 5: 点赞评论 - SQL 注入尝试
test_sql_injection \
  "点赞评论 - SQL 注入 (comment_id)" \
  "like-comment" \
  '{"comment_id": "'\'' OR 1=1--", "action": "like"}'

# 测试 6: 提交反馈 - SQL 注入尝试
test_sql_injection \
  "提交反馈 - SQL 注入 (content_id)" \
  "submit-feedback" \
  '{"contentId": "'\'' UNION SELECT password FROM users--", "isHelpful": true}'

# 测试 7: 获取内容详情 - SQL 注入尝试
test_sql_injection \
  "获取内容详情 - SQL 注入" \
  "get-content-detail" \
  "content_id=' OR '1'='1" \
  "GET"

# 测试 8: 管理后台搜索 - SQL 注入尝试
test_sql_injection \
  "管理后台搜索 - SQL 注入" \
  "admin-content-management" \
  "search='; DELETE FROM posts;--" \
  "GET"

# 测试 9: 无效 UUID 格式
test_sql_injection \
  "无效 UUID 格式" \
  "get-content-detail" \
  "content_id=not-a-uuid" \
  "GET"

# 测试 10: 超长输入
test_sql_injection \
  "超长输入 - 搜索查询" \
  "search-content" \
  "query=$(printf 'a%.0s' {1..200})" \
  "GET"

echo "=========================================="
echo "测试结果汇总"
echo "=========================================="
echo -e "总测试数: $TOTAL_TESTS"
echo -e "${GREEN}通过: $PASSED_TESTS${NC}"
echo -e "${RED}失败: $FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
  echo -e "${GREEN}✓ 所有 SQL 注入防护测试通过！${NC}"
  exit 0
else
  echo -e "${RED}✗ 部分测试失败，请检查 API 输入验证${NC}"
  exit 1
fi
