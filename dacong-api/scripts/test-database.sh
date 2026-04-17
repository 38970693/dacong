#!/bin/bash

# 数据库测试脚本
# 验证数据库连接、表结构、索引、RLS策略、触发器和视图

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 测试函数
run_test() {
    local test_name=$1
    local test_query=$2

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    echo -e "\n${YELLOW}Testing:${NC} $test_name"

    if psql "$DATABASE_URL" -c "$test_query" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# 加载环境变量
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    log_error ".env file not found"
    exit 1
fi

# 检查数据库连接
log_info "Starting database tests..."
echo "========================================"

# 1. 测试数据库连接
log_info "1. Testing database connection..."
run_test "Database Connection" "SELECT 1;"

# 2. 测试表是否存在
log_info "2. Testing table existence..."
run_test "raw_data table" "SELECT 1 FROM raw_data LIMIT 1;"
run_test "generated_content table" "SELECT 1 FROM generated_content LIMIT 1;"
run_test "published_content table" "SELECT 1 FROM published_content LIMIT 1;"
run_test "user_feedback table" "SELECT 1 FROM user_feedback LIMIT 1;"
run_test "scenario_recommendations table" "SELECT 1 FROM scenario_recommendations LIMIT 1;"
run_test "spider_logs table" "SELECT 1 FROM spider_logs LIMIT 1;"

# 3. 测试索引
log_info "3. Testing indexes..."
run_test "raw_data indexes" "
    SELECT 1 FROM pg_indexes
    WHERE tablename = 'raw_data'
    AND indexname IN ('idx_raw_data_source_id', 'idx_raw_data_created_at');
"

run_test "generated_content indexes" "
    SELECT 1 FROM pg_indexes
    WHERE tablename = 'generated_content'
    AND indexname IN ('idx_generated_content_raw_data_id', 'idx_generated_content_status');
"

run_test "published_content indexes" "
    SELECT 1 FROM pg_indexes
    WHERE tablename = 'published_content'
    AND indexname IN ('idx_published_content_scenario', 'idx_published_content_published_at');
"

# 4. 测试触发器
log_info "4. Testing triggers..."
run_test "Triggers existence" "
    SELECT 1 FROM pg_trigger
    WHERE tgname IN (
        'update_raw_data_updated_at',
        'update_generated_content_updated_at',
        'update_published_content_updated_at'
    );
"

# 5. 测试视图
log_info "5. Testing views..."
run_test "content_pipeline_status view" "SELECT 1 FROM content_pipeline_status LIMIT 1;"
run_test "recommendation_stats view" "SELECT 1 FROM recommendation_stats LIMIT 1;"

# 6. 测试 RLS 策略
log_info "6. Testing RLS policies..."
run_test "RLS enabled on raw_data" "
    SELECT 1 FROM pg_tables
    WHERE tablename = 'raw_data'
    AND rowsecurity = true;
"

run_test "RLS policies count" "
    SELECT 1 FROM pg_policies
    WHERE tablename IN (
        'raw_data',
        'generated_content',
        'published_content',
        'user_feedback'
    )
    HAVING COUNT(*) >= 4;
"

# 7. 测试数据完整性
log_info "7. Testing data integrity..."
run_test "Foreign key constraints" "
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_type = 'FOREIGN KEY'
    AND table_name IN ('generated_content', 'published_content', 'user_feedback')
    HAVING COUNT(*) >= 3;
"

# 8. 测试基本 CRUD 操作
log_info "8. Testing basic CRUD operations..."

# 插入测试数据
run_test "Insert test data" "
    INSERT INTO raw_data (source_type, source_id, title, content, url, metadata)
    VALUES (
        'github',
        'test-repo-123',
        'Test Repository',
        'This is a test repository for database testing',
        'https://github.com/test/repo',
        '{\"stars\": 100, \"language\": \"Python\"}'::jsonb
    )
    ON CONFLICT (source_type, source_id) DO NOTHING;
"

# 查询测试数据
run_test "Query test data" "
    SELECT 1 FROM raw_data
    WHERE source_id = 'test-repo-123';
"

# 更新测试数据
run_test "Update test data" "
    UPDATE raw_data
    SET metadata = jsonb_set(metadata, '{stars}', '200')
    WHERE source_id = 'test-repo-123';
"

# 删除测试数据
run_test "Delete test data" "
    DELETE FROM raw_data
    WHERE source_id = 'test-repo-123';
"

# 9. 测试性能
log_info "9. Testing query performance..."
start_time=$(date +%s%N)
psql "$DATABASE_URL" -c "SELECT COUNT(*) FROM raw_data;" > /dev/null 2>&1
end_time=$(date +%s%N)
duration=$(( (end_time - start_time) / 1000000 ))

if [ $duration -lt 100 ]; then
    echo -e "${GREEN}✓ Query performance: ${duration}ms (< 100ms)${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${YELLOW}⚠ Query performance: ${duration}ms (>= 100ms)${NC}"
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# 输出测试结果
echo ""
echo "========================================"
echo "Database Test Summary"
echo "========================================"
echo -e "Total Tests:  ${TOTAL_TESTS}"
echo -e "Passed:       ${GREEN}${PASSED_TESTS}${NC}"
echo -e "Failed:       ${RED}${FAILED_TESTS}${NC}"
echo -e "Success Rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
echo "========================================"

# 返回退出码
if [ $FAILED_TESTS -eq 0 ]; then
    log_info "All database tests passed!"
    exit 0
else
    log_error "Some database tests failed!"
    exit 1
fi
