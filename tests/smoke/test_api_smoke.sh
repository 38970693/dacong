#!/bin/bash

# ============================================
# API 冒烟测试
# ============================================
# 用途：快速验证所有 API 端点是否正常工作
# 使用：./tests/smoke/test_api_smoke.sh

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

log_info "开始 API 冒烟测试..."

# 测试计数器
PASSED=0
FAILED=0

# 测试函数
test_api() {
    local name="$1"
    local endpoint="$2"
    local method="${3:-POST}"
    local data="$4"

    log_info "测试: $name"

    local response
    local status_code

    if [ "$method" = "POST" ]; then
        response=$(curl -s -w "\n%{http_code}" \
            "$SUPABASE_URL/functions/v1/$endpoint" \
            -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
            -H "Content-Type: application/json" \
            -d "$data")
    else
        response=$(curl -s -w "\n%{http_code}" \
            "$SUPABASE_URL/functions/v1/$endpoint" \
            -H "Authorization: Bearer $SUPABASE_ANON_KEY")
    fi

    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)

    if [ "$status_code" = "200" ]; then
        log_success "✓ $name (HTTP $status_code)"
        ((PASSED++))
        return 0
    else
        log_error "✗ $name (HTTP $status_code)"
        echo "Response: $body"
        ((FAILED++))
        return 1
    fi
}

# ============================================
# 测试所有 API 端点
# ============================================

# 1. 推荐接口
test_api "推荐接口 - 早晨场景" \
    "get-recommendations" \
    "POST" \
    '{"user_id":"test-user","scenario":"morning","limit":5}'

test_api "推荐接口 - 午休场景" \
    "get-recommendations" \
    "POST" \
    '{"user_id":"test-user","scenario":"lunch","limit":5}'

test_api "推荐接口 - 晚间场景" \
    "get-recommendations" \
    "POST" \
    '{"user_id":"test-user","scenario":"evening","limit":5}'

# 2. 搜索接口
test_api "搜索接口 - 关键词搜索" \
    "search-content" \
    "POST" \
    '{"query":"技术","limit":10}'

test_api "搜索接口 - 空查询" \
    "search-content" \
    "POST" \
    '{"query":"","limit":10}'

# 3. 内容详情接口
test_api "内容详情接口" \
    "get-content-detail" \
    "POST" \
    '{"content_id":"test-id","user_id":"test-user"}'

# 4. 周报接口
test_api "周报接口" \
    "get-weekly-report" \
    "POST" \
    '{"user_id":"test-user"}'

# 5. 评论相关接口
test_api "获取评论列表" \
    "get-comments" \
    "POST" \
    '{"content_id":"test-id","limit":10,"offset":0}'

# 6. 实时统计接口
test_api "实时统计接口" \
    "get-realtime-stats" \
    "POST" \
    '{}'

# ============================================
# 测试总结
# ============================================
echo ""
log_info "=========================================="
log_info "API 冒烟测试完成"
log_info "=========================================="
log_success "通过: $PASSED"
log_error "失败: $FAILED"
log_info "总计: $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    log_success "所有 API 测试通过！"
    exit 0
else
    log_error "部分 API 测试失败"
    exit 1
fi
