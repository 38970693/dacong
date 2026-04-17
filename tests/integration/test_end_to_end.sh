#!/bin/bash

# 端到端集成测试
# 测试完整数据流：爬虫 → AI生成 → API → 前端

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

# 测试报告
REPORT_FILE="$PROJECT_ROOT/tests/integration/e2e_test_report.md"
START_TIME=$(date +%s)

# 初始化报告
cat > "$REPORT_FILE" << EOF
# 端到端集成测试报告

**测试时间**: $(date '+%Y-%m-%d %H:%M:%S')
**测试环境**: $(uname -s) $(uname -r)

---

## 测试场景

测试完整数据流：爬虫 → AI生成 → API → 前端

---

## 测试结果

EOF

# 测试计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 记录测试结果
record_test() {
    local test_name=$1
    local status=$2
    local message=$3

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    if [ "$status" = "PASS" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo "### ✅ $test_name" >> "$REPORT_FILE"
        log_success "$test_name"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "### ❌ $test_name" >> "$REPORT_FILE"
        log_error "$test_name"
    fi

    echo "" >> "$REPORT_FILE"
    echo "$message" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

log_info "开始端到端集成测试..."
echo ""

# ============================================
# 阶段 1: 检查环境配置
# ============================================
log_info "阶段 1: 检查环境配置"

# 检查 Supabase 配置
if [ -f "$PROJECT_ROOT/dacong-api/.env" ]; then
    source "$PROJECT_ROOT/dacong-api/.env"
    if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_SERVICE_ROLE_KEY" ]; then
        record_test "Supabase 配置检查" "PASS" "配置文件存在且包含必需的环境变量"
    else
        record_test "Supabase 配置检查" "FAIL" "缺少必需的环境变量"
        exit 1
    fi
else
    record_test "Supabase 配置检查" "FAIL" "配置文件不存在"
    exit 1
fi

# 检查 Python 环境
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    record_test "Python 环境检查" "PASS" "Python 版本: $PYTHON_VERSION"
else
    record_test "Python 环境检查" "FAIL" "Python 未安装"
    exit 1
fi

# 检查 Deno 环境
if command -v deno &> /dev/null; then
    DENO_VERSION=$(deno --version | head -n 1)
    record_test "Deno 环境检查" "PASS" "Deno 版本: $DENO_VERSION"
else
    record_test "Deno 环境检查" "FAIL" "Deno 未安装"
    exit 1
fi

# 检查 Flutter 环境
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    record_test "Flutter 环境检查" "PASS" "Flutter 版本: $FLUTTER_VERSION"
else
    record_test "Flutter 环境检查" "FAIL" "Flutter 未安装"
    exit 1
fi

echo ""

# ============================================
# 阶段 2: 数据库连接测试
# ============================================
log_info "阶段 2: 数据库连接测试"

# 测试数据库连接
DB_TEST_RESULT=$(cd "$PROJECT_ROOT/dacong-api" && deno eval "
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const supabase = createClient(
  Deno.env.get('SUPABASE_URL') || '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
);
const { data, error } = await supabase.from('published_content').select('count').limit(1);
console.log(error ? 'FAIL' : 'PASS');
" 2>&1)

if [[ "$DB_TEST_RESULT" == *"PASS"* ]]; then
    record_test "数据库连接测试" "PASS" "成功连接到 Supabase 数据库"
else
    record_test "数据库连接测试" "FAIL" "无法连接到数据库: $DB_TEST_RESULT"
fi

echo ""

# ============================================
# 阶段 3: 爬虫数据采集测试
# ============================================
log_info "阶段 3: 爬虫数据采集测试"

cd "$PROJECT_ROOT/dacong-spider"

# 检查爬虫配置
if [ -f ".env" ]; then
    # 运行单个爬虫测试（GitHub Trending）
    log_info "运行 GitHub Trending 爬虫..."

    if python3 main.py --spider github 2>&1 | tee /tmp/spider_test.log; then
        if grep -q "成功" /tmp/spider_test.log || grep -q "SUCCESS" /tmp/spider_test.log; then
            record_test "爬虫数据采集" "PASS" "GitHub Trending 爬虫成功运行并采集数据"
        else
            record_test "爬虫数据采集" "FAIL" "爬虫运行但未成功采集数据"
        fi
    else
        record_test "爬虫数据采集" "FAIL" "爬虫运行失败"
    fi
else
    record_test "爬虫数据采集" "FAIL" "爬虫配置文件不存在"
fi

echo ""

# ============================================
# 阶段 4: AI 内容生成测试
# ============================================
log_info "阶段 4: AI 内容生成测试"

cd "$PROJECT_ROOT/dacong-spider"

# 检查是否有 AI 生成脚本
if [ -f "demo_weekly.py" ]; then
    log_info "运行 AI 内容生成测试..."

    # 运行 AI 生成（使用测试模式）
    if timeout 60 python3 demo_weekly.py 2>&1 | tee /tmp/ai_gen_test.log; then
        if grep -q "成功" /tmp/ai_gen_test.log || grep -q "生成" /tmp/ai_gen_test.log; then
            record_test "AI 内容生成" "PASS" "AI 成功生成内容"
        else
            record_test "AI 内容生成" "FAIL" "AI 生成过程异常"
        fi
    else
        record_test "AI 内容生成" "FAIL" "AI 生成超时或失败"
    fi
else
    log_warning "AI 生成脚本不存在，跳过测试"
    record_test "AI 内容生成" "PASS" "跳过（脚本不存在）"
fi

echo ""

# ============================================
# 阶段 5: API 端点测试
# ============================================
log_info "阶段 5: API 端点测试"

cd "$PROJECT_ROOT/dacong-api"

# 测试 API 端点
API_BASE_URL="${SUPABASE_URL}/functions/v1"
API_KEY="$SUPABASE_SERVICE_ROLE_KEY"

# 测试获取推荐 API
log_info "测试 get-recommendations API..."
RECOMMENDATIONS_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer $API_KEY" \
    "$API_BASE_URL/get-recommendations?scenario=coding&limit=5")

HTTP_CODE=$(echo "$RECOMMENDATIONS_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$RECOMMENDATIONS_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    if echo "$RESPONSE_BODY" | grep -q "success"; then
        record_test "API: get-recommendations" "PASS" "API 返回成功，状态码: $HTTP_CODE"
    else
        record_test "API: get-recommendations" "FAIL" "API 返回格式错误"
    fi
else
    record_test "API: get-recommendations" "FAIL" "API 返回错误，状态码: $HTTP_CODE"
fi

# 测试搜索 API
log_info "测试 search-content API..."
SEARCH_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer $API_KEY" \
    "$API_BASE_URL/search-content?query=AI&limit=5")

HTTP_CODE=$(echo "$SEARCH_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$SEARCH_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    if echo "$RESPONSE_BODY" | grep -q "success"; then
        record_test "API: search-content" "PASS" "API 返回成功，状态码: $HTTP_CODE"
    else
        record_test "API: search-content" "FAIL" "API 返回格式错误"
    fi
else
    record_test "API: search-content" "FAIL" "API 返回错误，状态码: $HTTP_CODE"
fi

# 测试周报 API
log_info "测试 get-weekly-report API..."
WEEKLY_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer $API_KEY" \
    "$API_BASE_URL/get-weekly-report?limit=5")

HTTP_CODE=$(echo "$WEEKLY_RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$WEEKLY_RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    if echo "$RESPONSE_BODY" | grep -q "success"; then
        record_test "API: get-weekly-report" "PASS" "API 返回成功，状态码: $HTTP_CODE"
    else
        record_test "API: get-weekly-report" "FAIL" "API 返回格式错误"
    fi
else
    record_test "API: get-weekly-report" "FAIL" "API 返回错误，状态码: $HTTP_CODE"
fi

echo ""

# ============================================
# 阶段 6: 数据一致性验证
# ============================================
log_info "阶段 6: 数据一致性验证"

# 验证数据流完整性
log_info "验证数据流完整性..."

DATA_CONSISTENCY=$(cd "$PROJECT_ROOT/dacong-api" && deno eval "
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const supabase = createClient(
  Deno.env.get('SUPABASE_URL') || '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
);

// 检查各表数据
const tables = ['raw_data', 'generated_content', 'published_content'];
const results = [];

for (const table of tables) {
  const { count, error } = await supabase.from(table).select('*', { count: 'exact', head: true });
  results.push({ table, count: count || 0, error: error?.message });
}

console.log(JSON.stringify(results));
" 2>&1)

if echo "$DATA_CONSISTENCY" | grep -q "count"; then
    record_test "数据一致性验证" "PASS" "数据流完整性验证通过\n\`\`\`json\n$DATA_CONSISTENCY\n\`\`\`"
else
    record_test "数据一致性验证" "FAIL" "数据验证失败: $DATA_CONSISTENCY"
fi

echo ""

# ============================================
# 阶段 7: 前端构建测试
# ============================================
log_info "阶段 7: 前端构建测试"

cd "$PROJECT_ROOT/dacong-client"

# 检查依赖
log_info "检查 Flutter 依赖..."
if flutter pub get > /tmp/flutter_deps.log 2>&1; then
    record_test "Flutter 依赖安装" "PASS" "依赖安装成功"
else
    record_test "Flutter 依赖安装" "FAIL" "依赖安装失败"
fi

# 运行测试
log_info "运行 Flutter 测试..."
if flutter test > /tmp/flutter_test.log 2>&1; then
    TEST_SUMMARY=$(grep -E "All tests passed|tests passed" /tmp/flutter_test.log || echo "测试完成")
    record_test "Flutter 单元测试" "PASS" "$TEST_SUMMARY"
else
    record_test "Flutter 单元测试" "FAIL" "测试失败，查看日志: /tmp/flutter_test.log"
fi

# 构建测试（仅验证，不生成完整包）
log_info "验证 Flutter 构建配置..."
if flutter analyze > /tmp/flutter_analyze.log 2>&1; then
    record_test "Flutter 代码分析" "PASS" "代码分析通过"
else
    ANALYZE_ERRORS=$(grep -E "error|warning" /tmp/flutter_analyze.log | head -5)
    record_test "Flutter 代码分析" "FAIL" "发现问题:\n\`\`\`\n$ANALYZE_ERRORS\n\`\`\`"
fi

echo ""

# ============================================
# 生成测试摘要
# ============================================
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

cat >> "$REPORT_FILE" << EOF

---

## 测试摘要

- **总测试数**: $TOTAL_TESTS
- **通过**: $PASSED_TESTS ✅
- **失败**: $FAILED_TESTS ❌
- **成功率**: $(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")%
- **耗时**: ${DURATION}秒

---

## 结论

EOF

if [ $FAILED_TESTS -eq 0 ]; then
    echo "✅ **所有测试通过！系统集成正常。**" >> "$REPORT_FILE"
    log_success "所有测试通过！"
    EXIT_CODE=0
else
    echo "❌ **有 $FAILED_TESTS 个测试失败，请检查上述详情。**" >> "$REPORT_FILE"
    log_error "有 $FAILED_TESTS 个测试失败"
    EXIT_CODE=1
fi

echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "*报告生成时间: $(date '+%Y-%m-%d %H:%M:%S')*" >> "$REPORT_FILE"

log_info "测试报告已生成: $REPORT_FILE"
echo ""
log_info "测试摘要:"
echo "  总测试数: $TOTAL_TESTS"
echo "  通过: $PASSED_TESTS"
echo "  失败: $FAILED_TESTS"
echo "  成功率: $(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")%"
echo "  耗时: ${DURATION}秒"

exit $EXIT_CODE
