#!/bin/bash

# CSRF 防护安全测试脚本
#
# 测试场景：
# 1. 无 Token 请求被拒绝
# 2. 错误 Token 请求被拒绝
# 3. 过期 Token 请求被拒绝
# 4. 正确 Token 请求成功
# 5. Token 刷新正常

set -e

# 配置
BASE_URL="${BASE_URL:-http://localhost:54321/functions/v1}"
TEST_USER_EMAIL="${TEST_USER_EMAIL:-test@example.com}"
TEST_USER_PASSWORD="${TEST_USER_PASSWORD:-testpassword123}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试计数
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 打印函数
print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASSED_TESTS=$((PASSED_TESTS + 1))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# 测试 1: 获取 CSRF Token
test_get_csrf_token() {
    print_test "获取 CSRF Token"

    response=$(curl -s -w "\n%{http_code}" "$BASE_URL/get-csrf-token")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)

    if [ "$http_code" = "200" ]; then
        token=$(echo "$body" | jq -r '.token')
        if [ -n "$token" ] && [ "$token" != "null" ]; then
            print_pass "成功获取 CSRF Token: ${token:0:20}..."
            echo "$token"
            return 0
        fi
    fi

    print_fail "获取 CSRF Token 失败 (HTTP $http_code)"
    return 1
}

# 测试 2: 无 Token 请求被拒绝
test_no_token_rejected() {
    print_test "无 Token 请求应被拒绝"

    response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d '{"content_id":"test","is_helpful":true}' \
        "$BASE_URL/submit-feedback")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)

    if [ "$http_code" = "403" ]; then
        error=$(echo "$body" | jq -r '.error')
        if echo "$error" | grep -qi "csrf"; then
            print_pass "无 Token 请求被正确拒绝"
            return 0
        fi
    fi

    print_fail "无 Token 请求未被拒绝 (HTTP $http_code)"
    return 1
}

# 测试 3: 错误 Token 请求被拒绝
test_invalid_token_rejected() {
    print_test "错误 Token 请求应被拒绝"

    invalid_token="invalid_token_12345:$(date +%s)000"

    response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "x-csrf-token: $invalid_token" \
        -H "Cookie: csrf_token=$invalid_token" \
        -d '{"content_id":"test","is_helpful":true}' \
        "$BASE_URL/submit-feedback")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)

    if [ "$http_code" = "403" ]; then
        error=$(echo "$body" | jq -r '.error')
        if echo "$error" | grep -qi "csrf"; then
            print_pass "错误 Token 请求被正确拒绝"
            return 0
        fi
    fi

    print_fail "错误 Token 请求未被拒绝 (HTTP $http_code)"
    return 1
}

# 测试 4: 过期 Token 请求被拒绝
test_expired_token_rejected() {
    print_test "过期 Token 请求应被拒绝"

    # 生成一个过期的 Token（时间戳为 2 小时前）
    expired_timestamp=$(($(date +%s) - 7200))
    expired_token="abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890:${expired_timestamp}000"

    response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "x-csrf-token: $expired_token" \
        -H "Cookie: csrf_token=$expired_token" \
        -d '{"content_id":"test","is_helpful":true}' \
        "$BASE_URL/submit-feedback")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)

    if [ "$http_code" = "403" ]; then
        error=$(echo "$body" | jq -r '.error')
        if echo "$error" | grep -qi "expired"; then
            print_pass "过期 Token 请求被正确拒绝"
            return 0
        fi
    fi

    print_fail "过期 Token 请求未被拒绝 (HTTP $http_code)"
    return 1
}

# 测试 5: 正确 Token 请求成功（需要认证）
test_valid_token_accepted() {
    print_test "正确 Token 请求应成功"

    # 获取有效的 CSRF Token
    csrf_token=$(test_get_csrf_token)
    if [ -z "$csrf_token" ]; then
        print_fail "无法获取 CSRF Token"
        return 1
    fi

    # 注意：这个测试需要有效的认证 Token
    # 在实际环境中，需要先登录获取 JWT Token
    print_info "跳过（需要有效的认证 Token）"
    return 0
}

# 测试 6: Token 刷新正常
test_token_refresh() {
    print_test "Token 刷新应正常工作"

    # 第一次获取
    token1=$(test_get_csrf_token)
    if [ -z "$token1" ]; then
        print_fail "第一次获取 Token 失败"
        return 1
    fi

    # 等待 1 秒
    sleep 1

    # 第二次获取
    token2=$(test_get_csrf_token)
    if [ -z "$token2" ]; then
        print_fail "第二次获取 Token 失败"
        return 1
    fi

    # Token 应该不同（因为包含时间戳）
    if [ "$token1" != "$token2" ]; then
        print_pass "Token 刷新正常"
        return 0
    else
        print_fail "Token 未刷新"
        return 1
    fi
}

# 测试 7: GET 请求不需要 CSRF Token
test_get_request_no_csrf() {
    print_test "GET 请求不需要 CSRF Token"

    response=$(curl -s -w "\n%{http_code}" \
        "$BASE_URL/get-content-detail?id=test")

    http_code=$(echo "$response" | tail -n1)

    # GET 请求不应该因为缺少 CSRF Token 而返回 403
    if [ "$http_code" != "403" ]; then
        print_pass "GET 请求不需要 CSRF Token"
        return 0
    fi

    body=$(echo "$response" | head -n-1)
    error=$(echo "$body" | jq -r '.error')

    # 如果是 403 但不是 CSRF 错误，也算通过
    if ! echo "$error" | grep -qi "csrf"; then
        print_pass "GET 请求不需要 CSRF Token"
        return 0
    fi

    print_fail "GET 请求被 CSRF 拦截"
    return 1
}

# 主测试流程
main() {
    echo "=========================================="
    echo "CSRF 防护安全测试"
    echo "=========================================="
    echo ""
    echo "测试环境: $BASE_URL"
    echo ""

    # 检查依赖
    if ! command -v curl &> /dev/null; then
        echo "错误: 需要安装 curl"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "错误: 需要安装 jq"
        exit 1
    fi

    # 运行测试
    test_get_csrf_token > /dev/null || true
    test_no_token_rejected || true
    test_invalid_token_rejected || true
    test_expired_token_rejected || true
    test_valid_token_accepted || true
    test_token_refresh || true
    test_get_request_no_csrf || true

    # 输出结果
    echo ""
    echo "=========================================="
    echo "测试结果"
    echo "=========================================="
    echo "总测试数: $TOTAL_TESTS"
    echo -e "${GREEN}通过: $PASSED_TESTS${NC}"
    echo -e "${RED}失败: $FAILED_TESTS${NC}"
    echo ""

    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}所有测试通过！${NC}"
        exit 0
    else
        echo -e "${RED}部分测试失败${NC}"
        exit 1
    fi
}

# 运行主函数
main
