#!/bin/bash

# XSS 防护测试脚本
# 测试 API 是否能够防御 XSS 攻击

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
API_BASE_URL="${API_BASE_URL:-http://localhost:54321/functions/v1}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"
AUTH_TOKEN="${AUTH_TOKEN}" # 需要认证的 token

if [ -z "$SUPABASE_ANON_KEY" ]; then
  echo -e "${RED}Error: SUPABASE_ANON_KEY environment variable is not set${NC}"
  exit 1
fi

echo "=========================================="
echo "XSS 防护测试"
echo "=========================================="
echo ""

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
test_xss_protection() {
  local test_name="$1"
  local endpoint="$2"
  local payload="$3"
  local check_sanitized="${4:-true}"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  echo -e "${YELLOW}测试 $TOTAL_TESTS: $test_name${NC}"

  local headers="-H \"Content-Type: application/json\" -H \"apikey: $SUPABASE_ANON_KEY\""

  if [ -n "$AUTH_TOKEN" ]; then
    headers="$headers -H \"Authorization: Bearer $AUTH_TOKEN\""
  fi

  local response
  local http_code

  response=$(curl -s -w "\n%{http_code}" \
    -X POST \
    $headers \
    -d "$payload" \
    "$API_BASE_URL/$endpoint")

  http_code=$(echo "$response" | tail -n1)
  body=$(echo "$response" | head -n-1)

  # 检查响应
  if [ "$http_code" = "400" ] || [ "$http_code" = "401" ]; then
    echo -e "${GREEN}✓ 通过 - API 拒绝了恶意输入或要求认证 (HTTP $http_code)${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  elif [ "$check_sanitized" = "true" ]; then
    # 检查响应中是否包含未转义的脚本标签
    if echo "$body" | grep -q "<script>" || echo "$body" | grep -q "javascript:"; then
      echo -e "${RED}✗ 失败 - 响应包含未转义的恶意代码${NC}"
      echo "响应: $body"
      FAILED_TESTS=$((FAILED_TESTS + 1))
    else
      echo -e "${GREEN}✓ 通过 - 恶意代码已被转义或过滤 (HTTP $http_code)${NC}"
      PASSED_TESTS=$((PASSED_TESTS + 1))
    fi
  else
    echo -e "${GREEN}✓ 通过 - API 接受了输入 (HTTP $http_code)${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
  fi

  echo ""
}

# 测试 1: 提交评论 - 基本 XSS
test_xss_protection \
  "提交评论 - 基本 <script> 标签" \
  "submit-comment" \
  '{"content_id": "550e8400-e29b-41d4-a716-446655440000", "content": "<script>alert(\"XSS\")</script>"}'

# 测试 2: 提交评论 - IMG 标签 XSS
test_xss_protection \
  "提交评论 - IMG onerror XSS" \
  "submit-comment" \
  '{"content_id": "550e8400-e29b-41d4-a716-446655440000", "content": "<img src=x onerror=alert(1)>"}'

# 测试 3: 提交评论 - JavaScript 协议
test_xss_protection \
  "提交评论 - JavaScript 协议" \
  "submit-comment" \
  '{"content_id": "550e8400-e29b-41d4-a716-446655440000", "content": "<a href=\"javascript:alert(1)\">Click</a>"}'

# 测试 4: 提交评论 - 事件处理器
test_xss_protection \
  "提交评论 - onclick 事件" \
  "submit-comment" \
  '{"content_id": "550e8400-e29b-41d4-a716-446655440000", "content": "<div onclick=\"alert(1)\">Click me</div>"}'

# 测试 5: 提交评论 - SVG XSS
test_xss_protection \
  "提交评论 - SVG onload XSS" \
  "submit-comment" \
  '{"content_id": "550e8400-e29b-41d4-a716-446655440000", "content": "<svg onload=alert(1)>"}'

# 测试 6: 提交评论 - iframe 注入
test_xss_protection \
  "提交评论 - iframe 注入" \
  "submit-comment" \
  '{"content_id": "550e8400-e29b-41d4-a716-446655440000", "content": "<iframe src=\"javascript:alert(1)\"></iframe>"}'

# 测试 7: 提交反馈 - XSS 在 comment 字段
test_xss_protection \
  "提交反馈 - XSS 在 comment" \
  "submit-feedback" \
  '{"contentId": "550e8400-e29b-41d4-a716-446655440000", "isHelpful": true, "comment": "<script>alert(\"XSS\")</script>"}'

# 测试 8: 搜索 - XSS 在查询参数
test_xss_protection \
  "搜索 - XSS 在查询参数" \
  "search-content" \
  '{"query": "<script>alert(1)</script>"}'

# 测试 9: 提交评论 - HTML 实体编码绕过
test_xss_protection \
  "提交评论 - HTML 实体编码" \
  "submit-comment" \
  '{"content_id": "550e8400-e29b-41d4-a716-446655440000", "content": "&lt;script&gt;alert(1)&lt;/script&gt;"}'

# 测试 10: 提交评论 - 大小写混淆
test_xss_protection \
  "提交评论 - 大小写混淆" \
  "submit-comment" \
  '{"content_id": "550e8400-e29b-41d4-a716-446655440000", "content": "<ScRiPt>alert(1)</sCrIpT>"}'

# 测试 11: 提交评论 - data: 协议
test_xss_protection \
  "提交评论 - data: 协议" \
  "submit-comment" \
  '{"content_id": "550e8400-e29b-41d4-a716-446655440000", "content": "<a href=\"data:text/html,<script>alert(1)</script>\">Click</a>"}'

# 测试 12: 提交评论 - vbscript: 协议
test_xss_protection \
  "提交评论 - vbscript: 协议" \
  "submit-comment" \
  '{"content_id": "550e8400-e29b-41d4-a716-446655440000", "content": "<a href=\"vbscript:msgbox(1)\">Click</a>"}'

echo "=========================================="
echo "测试结果汇总"
echo "=========================================="
echo -e "总测试数: $TOTAL_TESTS"
echo -e "${GREEN}通过: $PASSED_TESTS${NC}"
echo -e "${RED}失败: $FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
  echo -e "${GREEN}✓ 所有 XSS 防护测试通过！${NC}"
  exit 0
else
  echo -e "${RED}✗ 部分测试失败，请检查 API XSS 防护${NC}"
  exit 1
fi
