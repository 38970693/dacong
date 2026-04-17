#!/bin/bash

# ============================================
# 端到端冒烟测试
# ============================================
# 用途：测试完整的用户流程
# 使用：./tests/smoke/test_e2e_smoke.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 获取项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# 加载环境变量
if [ -f "$PROJECT_ROOT/.env.test.local" ]; then
    set -a
    source "$PROJECT_ROOT/.env.test.local"
    set +a
fi

log_info "开始端到端冒烟测试..."

# 测试计数器
PASSED=0
FAILED=0

# 生成测试用户 ID
TEST_USER_ID="test-user-$(date +%s)"

# ============================================
# 场景 1: 用户获取推荐内容
# ============================================
log_info "场景 1: 用户获取推荐内容"

# 1.1 获取早晨推荐
log_info "  1.1 获取早晨推荐..."
RESPONSE=$(curl -s "$SUPABASE_URL/functions/v1/get-recommendations" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"user_id\":\"$TEST_USER_ID\",\"scenario\":\"morning\",\"limit\":5}")

if echo "$RESPONSE" | grep -q "recommendations"; then
    log_success "  ✓ 获取早晨推荐成功"
    ((PASSED++))
else
    log_error "  ✗ 获取早晨推荐失败"
    ((FAILED++))
fi

# 1.2 提取第一个内容 ID
CONTENT_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$CONTENT_ID" ]; then
    log_success "  ✓ 提取内容 ID: $CONTENT_ID"
    ((PASSED++))
else
    log_error "  ✗ 未能提取内容 ID"
    ((FAILED++))
    CONTENT_ID="test-content-id"  # 使用默认值继续测试
fi

# ============================================
# 场景 2: 用户查看内容详情
# ============================================
log_info "场景 2: 用户查看内容详情"

# 2.1 获取内容详情
log_info "  2.1 获取内容详情..."
DETAIL_RESPONSE=$(curl -s "$SUPABASE_URL/functions/v1/get-content-detail" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"content_id\":\"$CONTENT_ID\",\"user_id\":\"$TEST_USER_ID\"}")

if echo "$DETAIL_RESPONSE" | grep -q "content"; then
    log_success "  ✓ 获取内容详情成功"
    ((PASSED++))
else
    log_error "  ✗ 获取内容详情失败"
    ((FAILED++))
fi

# ============================================
# 场景 3: 用户搜索内容
# ============================================
log_info "场景 3: 用户搜索内容"

# 3.1 搜索关键词
log_info "  3.1 搜索关键词..."
SEARCH_RESPONSE=$(curl -s "$SUPABASE_URL/functions/v1/search-content" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json" \
    -d '{"query":"技术","limit":10}')

if echo "$SEARCH_RESPONSE" | grep -q "results"; then
    log_success "  ✓ 搜索成功"
    ((PASSED++))
else
    log_error "  ✗ 搜索失败"
    ((FAILED++))
fi

# ============================================
# 场景 4: 用户查看评论
# ============================================
log_info "场景 4: 用户查看评论"

# 4.1 获取评论列表
log_info "  4.1 获取评论列表..."
COMMENTS_RESPONSE=$(curl -s "$SUPABASE_URL/functions/v1/get-comments" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"content_id\":\"$CONTENT_ID\",\"limit\":10}")

if echo "$COMMENTS_RESPONSE" | grep -q "comments"; then
    log_success "  ✓ 获取评论列表成功"
    ((PASSED++))
else
    log_error "  ✗ 获取评论列表失败"
    ((FAILED++))
fi

# ============================================
# 场景 5: 用户查看周报
# ============================================
log_info "场景 5: 用户查看周报"

# 5.1 获取周报
log_info "  5.1 获取周报..."
REPORT_RESPONSE=$(curl -s "$SUPABASE_URL/functions/v1/get-weekly-report" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"user_id\":\"$TEST_USER_ID\"}")

if echo "$REPORT_RESPONSE" | grep -q "report"; then
    log_success "  ✓ 获取周报成功"
    ((PASSED++))
else
    log_error "  ✗ 获取周报失败"
    ((FAILED++))
fi

# ============================================
# 场景 6: 完整用户旅程
# ============================================
log_info "场景 6: 完整用户旅程"

log_info "  模拟用户完整流程:"
log_info "    1. 打开应用 → 获取推荐"
log_info "    2. 点击内容 → 查看详情"
log_info "    3. 阅读评论 → 获取评论列表"
log_info "    4. 搜索内容 → 搜索结果"
log_info "    5. 查看周报 → 周报数据"

if [ $FAILED -eq 0 ]; then
    log_success "  ✓ 完整用户旅程测试通过"
    ((PASSED++))
else
    log_error "  ✗ 完整用户旅程存在问题"
    ((FAILED++))
fi

# ============================================
# 测试总结
# ============================================
echo ""
log_info "=========================================="
log_info "端到端冒烟测试完成"
log_info "=========================================="
log_success "通过: $PASSED"
log_error "失败: $FAILED"
log_info "总计: $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    log_success "所有端到端测试通过！"
    exit 0
else
    log_error "部分端到端测试失败"
    exit 1
fi
