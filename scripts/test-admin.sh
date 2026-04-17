#!/bin/bash

# 运营后台测试脚本

set -e

echo "=========================================="
echo "运营后台测试套件"
echo "=========================================="

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查环境变量
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo -e "${RED}错误: 请设置 SUPABASE_URL 和 SUPABASE_ANON_KEY 环境变量${NC}"
  exit 1
fi

echo -e "${YELLOW}1. 运行 Flutter Widget 测试...${NC}"
cd dacong-admin
flutter test test/pages/login_page_test.dart
flutter test test/services/admin_api_service_test.dart
echo -e "${GREEN}✓ Flutter 测试完成${NC}"
echo ""

echo -e "${YELLOW}2. 运行 Deno API 测试...${NC}"
cd ../dacong-api/supabase/functions
deno test --allow-net --allow-env tests/auth_middleware_test.ts
deno test --allow-net --allow-env tests/admin_api_test.ts
echo -e "${GREEN}✓ API 测试完成${NC}"
echo ""

echo -e "${YELLOW}3. 测试数据库迁移...${NC}"
cd ../../
supabase db reset --local
echo -e "${GREEN}✓ 数据库迁移测试完成${NC}"
echo ""

echo -e "${GREEN}=========================================="
echo "所有测试通过！"
echo "==========================================${NC}"
