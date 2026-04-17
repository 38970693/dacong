#!/bin/bash

# 安全测试运行脚本
# 运行所有安全测试

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo "Dacong API 安全测试套件"
echo -e "==========================================${NC}"
echo ""

# 检查环境变量
if [ -z "$SUPABASE_ANON_KEY" ]; then
  echo -e "${RED}错误: SUPABASE_ANON_KEY 环境变量未设置${NC}"
  echo "请设置: export SUPABASE_ANON_KEY=\"your-anon-key\""
  exit 1
fi

# 设置默认值
export API_BASE_URL="${API_BASE_URL:-http://localhost:54321/functions/v1}"

echo -e "${BLUE}配置信息:${NC}"
echo "API Base URL: $API_BASE_URL"
echo "Supabase Anon Key: ${SUPABASE_ANON_KEY:0:20}..."
echo ""

# 测试计数器
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

# 运行测试套件
run_test_suite() {
  local test_name="$1"
  local test_script="$2"

  TOTAL_SUITES=$((TOTAL_SUITES + 1))

  echo -e "${YELLOW}运行测试套件: $test_name${NC}"
  echo "----------------------------------------"

  if bash "$test_script"; then
    echo -e "${GREEN}✓ $test_name 通过${NC}"
    PASSED_SUITES=$((PASSED_SUITES + 1))
  else
    echo -e "${RED}✗ $test_name 失败${NC}"
    FAILED_SUITES=$((FAILED_SUITES + 1))
  fi

  echo ""
}

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 运行 SQL 注入测试
run_test_suite "SQL 注入防护测试" "$SCRIPT_DIR/test_sql_injection.sh"

# 运行 XSS 测试
run_test_suite "XSS 防护测试" "$SCRIPT_DIR/test_xss.sh"

# 总结
echo -e "${BLUE}=========================================="
echo "测试套件总结"
echo -e "==========================================${NC}"
echo -e "总测试套件数: $TOTAL_SUITES"
echo -e "${GREEN}通过: $PASSED_SUITES${NC}"
echo -e "${RED}失败: $FAILED_SUITES${NC}"
echo ""

if [ $FAILED_SUITES -eq 0 ]; then
  echo -e "${GREEN}✓ 所有安全测试通过！${NC}"
  exit 0
else
  echo -e "${RED}✗ 部分测试失败，请检查安全防护${NC}"
  exit 1
fi
