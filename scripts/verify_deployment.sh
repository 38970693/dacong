#!/bin/bash

# ============================================
# DaCong 部署验证脚本
# ============================================
# 用途: 验证部署后的系统功能
# 使用: ./scripts/verify_deployment.sh

set -e
set -u

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 加载环境变量
if [ -f "$PROJECT_ROOT/.env.test" ]; then
    set -a
    source "$PROJECT_ROOT/.env.test"
    set +a
else
    log_error "缺少 .env.test 文件"
    exit 1
fi

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    log_info "测试 $TOTAL_TESTS: $test_name"

    if eval "$test_command"; then
        log_success "通过"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        log_error "失败"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# ============================================
# 测试 1: 数据库连接
# ============================================
test_database_connection() {
    psql "$DATABASE_URL" -c "SELECT 1" &> /dev/null
}

# ============================================
# 测试 2: 数据库表结构
# ============================================
test_database_schema() {
    local tables=("raw_data" "generated_content" "published_content" "user_feedback" "spider_logs")

    for table in "${tables[@]}"; do
        if ! psql "$DATABASE_URL" -c "SELECT 1 FROM $table LIMIT 1" &> /dev/null; then
            return 1
        fi
    done

    return 0
}

# ============================================
# 测试 3: 推荐接口
# ============================================
test_recommendations_api() {
    local url="${SUPABASE_URL}/functions/v1/get-recommendations"
    local response=$(curl -s -X POST "$url" \
        -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
        -H "Content-Type: application/json" \
        -d '{"scenario": "morning_commute", "limit": 5}')

    # 检查响应是否包含 success 字段
    if echo "$response" | jq -e '.success' &> /dev/null; then
        return 0
    else
        log_error "响应: $response"
        return 1
    fi
}

# ============================================
# 测试 4: 搜索接口
# ============================================
test_search_api() {
    local url="${SUPABASE_URL}/functions/v1/search-content"
    local response=$(curl -s -X POST "$url" \
        -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
        -H "Content-Type: application/json" \
        -d '{"query": "AI", "limit": 5}')

    if echo "$response" | jq -e '.success' &> /dev/null; then
        return 0
    else
        log_error "响应: $response"
        return 1
    fi
}

# ============================================
# 测试 5: 内容详情接口
# ============================================
test_content_detail_api() {
    # 先获取一个内容 ID
    local content_id=$(psql "$DATABASE_URL" -t -c "SELECT id FROM published_content LIMIT 1" | xargs)

    if [ -z "$content_id" ]; then
        log_warning "没有发布的内容，跳过测试"
        return 0
    fi

    local url="${SUPABASE_URL}/functions/v1/get-content-detail"
    local response=$(curl -s -X POST "$url" \
        -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"content_id\": $content_id}")

    if echo "$response" | jq -e '.success' &> /dev/null; then
        return 0
    else
        log_error "响应: $response"
        return 1
    fi
}

# ============================================
# 测试 6: 周报接口
# ============================================
test_weekly_report_api() {
    local url="${SUPABASE_URL}/functions/v1/get-weekly-report"
    local response=$(curl -s -X POST "$url" \
        -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
        -H "Content-Type: application/json" \
        -d '{"limit": 10}')

    if echo "$response" | jq -e '.success' &> /dev/null; then
        return 0
    else
        log_error "响应: $response"
        return 1
    fi
}

# ============================================
# 测试 7: 反馈提交接口
# ============================================
test_feedback_api() {
    # 先获取一个内容 ID
    local content_id=$(psql "$DATABASE_URL" -t -c "SELECT id FROM published_content LIMIT 1" | xargs)

    if [ -z "$content_id" ]; then
        log_warning "没有发布的内容，跳过测试"
        return 0
    fi

    local url="${SUPABASE_URL}/functions/v1/submit-feedback"
    local response=$(curl -s -X POST "$url" \
        -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"content_id\": $content_id, \"feedback_type\": \"like\", \"rating\": 5}")

    if echo "$response" | jq -e '.success' &> /dev/null; then
        return 0
    else
        log_error "响应: $response"
        return 1
    fi
}

# ============================================
# 测试 8: API 响应时间
# ============================================
test_api_performance() {
    local url="${SUPABASE_URL}/functions/v1/get-recommendations"

    local start_time=$(date +%s%N)
    curl -s -X POST "$url" \
        -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
        -H "Content-Type: application/json" \
        -d '{"scenario": "morning_commute", "limit": 5}' \
        > /dev/null
    local end_time=$(date +%s%N)

    local response_time=$(( (end_time - start_time) / 1000000 ))

    log_info "API 响应时间: ${response_time}ms"

    if [ "$response_time" -lt 5000 ]; then
        return 0
    else
        log_error "响应时间过长: ${response_time}ms"
        return 1
    fi
}

# ============================================
# 测试 9: 数据完整性
# ============================================
test_data_integrity() {
    local raw_count=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM raw_data" | xargs)
    local gen_count=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM generated_content" | xargs)

    log_info "原始数据: $raw_count 条"
    log_info "生成内容: $gen_count 条"

    if [ "$raw_count" -gt 0 ]; then
        return 0
    else
        log_warning "原始数据为空"
        return 1
    fi
}

# ============================================
# 测试 10: CORS 配置
# ============================================
test_cors() {
    local url="${SUPABASE_URL}/functions/v1/get-recommendations"

    local cors_headers=$(curl -s -I -X OPTIONS "$url" \
        -H "Origin: http://localhost:3000" \
        -H "Access-Control-Request-Method: POST" | grep -i "access-control")

    if [ -n "$cors_headers" ]; then
        log_info "CORS 配置正常"
        return 0
    else
        log_warning "CORS 配置可能有问题"
        return 1
    fi
}

# ============================================
# 主流程
# ============================================
main() {
    log_info "=========================================="
    log_info "DaCong 部署验证测试"
    log_info "=========================================="
    log_info "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    # 运行所有测试
    run_test "数据库连接" "test_database_connection"
    echo ""

    run_test "数据库表结构" "test_database_schema"
    echo ""

    run_test "推荐接口" "test_recommendations_api"
    echo ""

    run_test "搜索接口" "test_search_api"
    echo ""

    run_test "内容详情接口" "test_content_detail_api"
    echo ""

    run_test "周报接口" "test_weekly_report_api"
    echo ""

    run_test "反馈提交接口" "test_feedback_api"
    echo ""

    run_test "API 响应时间" "test_api_performance"
    echo ""

    run_test "数据完整性" "test_data_integrity"
    echo ""

    run_test "CORS 配置" "test_cors"
    echo ""

    # 生成测试报告
    log_info "=========================================="
    log_info "测试报告"
    log_info "=========================================="
    log_info "总测试数: $TOTAL_TESTS"
    log_success "通过: $PASSED_TESTS"
    log_error "失败: $FAILED_TESTS"
    log_info "通过率: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
    echo ""

    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "所有测试通过！部署验证成功。"
        exit 0
    else
        log_error "部分测试失败，请检查上述错误信息。"
        exit 1
    fi
}

main "$@"
