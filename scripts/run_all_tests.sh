#!/bin/bash

# 运行所有测试并生成报告
# 包括：爬虫测试、API测试、前端测试

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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

log_section() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# 报告文件
REPORT_FILE="$PROJECT_ROOT/TEST_REPORT.md"
START_TIME=$(date +%s)

# 测试统计
declare -A TEST_RESULTS=(
    ["spider_unit"]=0
    ["spider_integration"]=0
    ["api_unit"]=0
    ["api_integration"]=0
    ["client_unit"]=0
    ["client_widget"]=0
)

declare -A TEST_COVERAGE=(
    ["spider"]=0
    ["api"]=0
    ["client"]=0
)

# 初始化报告
cat > "$REPORT_FILE" << EOF
# DaCong 完整测试报告

**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')
**测试环境**: $(uname -s) $(uname -r)

---

## 测试概览

本报告包含以下测试：

1. **爬虫模块测试** (dacong-spider)
   - 单元测试
   - 集成测试
   - 覆盖率统计

2. **API 模块测试** (dacong-api)
   - 单元测试
   - API 端点测试
   - 覆盖率统计

3. **客户端测试** (dacong-client)
   - 单元测试
   - Widget 测试
   - 覆盖率统计

---

EOF

log_section "开始运行所有测试"

# ============================================
# 1. 爬虫模块测试
# ============================================
log_section "1. 爬虫模块测试 (dacong-spider)"

cd "$PROJECT_ROOT/dacong-spider"

echo "## 爬虫模块测试" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 检查环境
if [ ! -f ".env" ]; then
    log_error "爬虫配置文件不存在，跳过测试"
    echo "⚠️ **配置文件缺失，测试跳过**" >> "$REPORT_FILE"
else
    # 运行单元测试
    log_info "运行爬虫单元测试..."

    if python3 -m pytest tests/ -v --cov=. --cov-report=term --cov-report=html:htmlcov > /tmp/spider_test.log 2>&1; then
        log_success "爬虫测试通过"

        # 提取测试结果
        SPIDER_TESTS=$(grep -oP '\d+(?= passed)' /tmp/spider_test.log || echo "0")
        SPIDER_COVERAGE=$(grep -oP '\d+(?=%)' /tmp/spider_test.log | tail -1 || echo "0")

        TEST_RESULTS["spider_unit"]=$SPIDER_TESTS
        TEST_COVERAGE["spider"]=$SPIDER_COVERAGE

        echo "### ✅ 单元测试通过" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "- **测试数量**: $SPIDER_TESTS" >> "$REPORT_FILE"
        echo "- **覆盖率**: ${SPIDER_COVERAGE}%" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    else
        log_error "爬虫测试失败"
        echo "### ❌ 单元测试失败" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        tail -20 /tmp/spider_test.log >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi

    # 运行集成测试
    log_info "运行爬虫集成测试..."

    if python3 -m pytest tests/test_integration.py -v > /tmp/spider_integration.log 2>&1; then
        INTEGRATION_TESTS=$(grep -oP '\d+(?= passed)' /tmp/spider_integration.log || echo "0")
        TEST_RESULTS["spider_integration"]=$INTEGRATION_TESTS

        echo "### ✅ 集成测试通过" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "- **测试数量**: $INTEGRATION_TESTS" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    else
        log_error "爬虫集成测试失败"
        echo "### ❌ 集成测试失败" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
fi

echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ============================================
# 2. API 模块测试
# ============================================
log_section "2. API 模块测试 (dacong-api)"

cd "$PROJECT_ROOT/dacong-api"

echo "## API 模块测试" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 运行单元测试
log_info "运行 API 单元测试..."

if [ -f "scripts/run-tests.sh" ]; then
    if bash scripts/run-tests.sh > /tmp/api_test.log 2>&1; then
        log_success "API 测试通过"

        # 提取测试结果
        API_TESTS=$(grep -oP '\d+(?= passed)' /tmp/api_test.log || echo "0")

        TEST_RESULTS["api_unit"]=$API_TESTS

        echo "### ✅ 单元测试通过" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "- **测试数量**: $API_TESTS" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    else
        log_error "API 测试失败"
        echo "### ❌ 单元测试失败" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
else
    log_error "API 测试脚本不存在"
    echo "⚠️ **测试脚本缺失**" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# 运行 API 端点测试
log_info "运行 API 端点测试..."

if [ -f "scripts/test-api.sh" ]; then
    if bash scripts/test-api.sh > /tmp/api_endpoint.log 2>&1; then
        log_success "API 端点测试通过"

        API_ENDPOINT_TESTS=$(grep -c "✓" /tmp/api_endpoint.log || echo "0")
        TEST_RESULTS["api_integration"]=$API_ENDPOINT_TESTS

        echo "### ✅ API 端点测试通过" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "- **测试数量**: $API_ENDPOINT_TESTS" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    else
        log_error "API 端点测试失败"
        echo "### ❌ API 端点测试失败" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
fi

echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ============================================
# 3. 客户端测试
# ============================================
log_section "3. 客户端测试 (dacong-client)"

cd "$PROJECT_ROOT/dacong-client"

echo "## 客户端测试" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 运行 Flutter 测试
log_info "运行 Flutter 测试..."

if flutter test --coverage > /tmp/flutter_test.log 2>&1; then
    log_success "Flutter 测试通过"

    # 提取测试结果
    CLIENT_TESTS=$(grep -oP '\d+(?= tests? passed)' /tmp/flutter_test.log || echo "0")
    TEST_RESULTS["client_unit"]=$CLIENT_TESTS

    echo "### ✅ 单元测试通过" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "- **测试数量**: $CLIENT_TESTS" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    # 生成覆盖率报告
    if [ -f "coverage/lcov.info" ]; then
        log_info "生成覆盖率报告..."

        # 使用 lcov 生成 HTML 报告（如果安装了）
        if command -v genhtml &> /dev/null; then
            genhtml coverage/lcov.info -o coverage/html > /dev/null 2>&1
            log_success "覆盖率报告已生成: coverage/html/index.html"
        fi

        # 提取覆盖率
        if command -v lcov &> /dev/null; then
            CLIENT_COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep -oP '\d+\.\d+(?=%)' | head -1 || echo "0")
            TEST_COVERAGE["client"]=${CLIENT_COVERAGE%.*}

            echo "- **覆盖率**: ${CLIENT_COVERAGE}%" >> "$REPORT_FILE"
            echo "" >> "$REPORT_FILE"
        fi
    fi
else
    log_error "Flutter 测试失败"
    echo "### ❌ 单元测试失败" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    tail -20 /tmp/flutter_test.log >> "$REPORT_FILE"
    echo "\`\`\`" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# 运行代码分析
log_info "运行 Flutter 代码分析..."

if flutter analyze > /tmp/flutter_analyze.log 2>&1; then
    log_success "代码分析通过"
    echo "### ✅ 代码分析通过" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
else
    log_error "代码分析发现问题"
    ANALYZE_ISSUES=$(grep -c "error\|warning" /tmp/flutter_analyze.log || echo "0")
    echo "### ⚠️ 代码分析发现 $ANALYZE_ISSUES 个问题" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ============================================
# 生成测试摘要
# ============================================
log_section "生成测试摘要"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# 计算总测试数
TOTAL_TESTS=0
for key in "${!TEST_RESULTS[@]}"; do
    TOTAL_TESTS=$((TOTAL_TESTS + ${TEST_RESULTS[$key]}))
done

# 计算平均覆盖率
TOTAL_COVERAGE=0
COVERAGE_COUNT=0
for key in "${!TEST_COVERAGE[@]}"; do
    if [ "${TEST_COVERAGE[$key]}" -gt 0 ]; then
        TOTAL_COVERAGE=$((TOTAL_COVERAGE + ${TEST_COVERAGE[$key]}))
        COVERAGE_COUNT=$((COVERAGE_COUNT + 1))
    fi
done

if [ $COVERAGE_COUNT -gt 0 ]; then
    AVG_COVERAGE=$((TOTAL_COVERAGE / COVERAGE_COUNT))
else
    AVG_COVERAGE=0
fi

cat >> "$REPORT_FILE" << EOF
## 测试摘要

### 测试统计

| 模块 | 单元测试 | 集成测试 | 覆盖率 |
|------|---------|---------|--------|
| 爬虫 | ${TEST_RESULTS["spider_unit"]} | ${TEST_RESULTS["spider_integration"]} | ${TEST_COVERAGE["spider"]}% |
| API | ${TEST_RESULTS["api_unit"]} | ${TEST_RESULTS["api_integration"]} | ${TEST_COVERAGE["api"]}% |
| 客户端 | ${TEST_RESULTS["client_unit"]} | ${TEST_RESULTS["client_widget"]} | ${TEST_COVERAGE["client"]}% |

### 总体统计

- **总测试数**: $TOTAL_TESTS
- **平均覆盖率**: ${AVG_COVERAGE}%
- **测试耗时**: ${DURATION}秒

---

## 覆盖率详情

### 爬虫模块
- HTML 报告: \`dacong-spider/htmlcov/index.html\`
- 覆盖率: ${TEST_COVERAGE["spider"]}%

### API 模块
- 覆盖率: ${TEST_COVERAGE["api"]}%

### 客户端模块
- HTML 报告: \`dacong-client/coverage/html/index.html\`
- 覆盖率: ${TEST_COVERAGE["client"]}%

---

## 建议

EOF

# 根据覆盖率给出建议
if [ $AVG_COVERAGE -lt 80 ]; then
    echo "⚠️ **覆盖率低于 80%，建议增加测试用例**" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
else
    echo "✅ **覆盖率达标（≥80%）**" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# 根据测试数量给出建议
if [ $TOTAL_TESTS -lt 50 ]; then
    echo "⚠️ **测试数量较少，建议增加更多测试场景**" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

---

## 下一步

1. 查看详细的覆盖率报告
2. 针对覆盖率低的模块增加测试
3. 修复失败的测试用例
4. 运行集成测试验证端到端流程

---

*报告生成时间: $(date '+%Y-%m-%d %H:%M:%S')*
EOF

log_success "测试报告已生成: $REPORT_FILE"
echo ""
log_info "测试摘要:"
echo "  总测试数: $TOTAL_TESTS"
echo "  平均覆盖率: ${AVG_COVERAGE}%"
echo "  测试耗时: ${DURATION}秒"
echo ""

# 打开报告（可选）
if command -v xdg-open &> /dev/null; then
    log_info "使用默认浏览器打开报告..."
    xdg-open "$REPORT_FILE" 2>/dev/null &
elif command -v open &> /dev/null; then
    log_info "使用默认浏览器打开报告..."
    open "$REPORT_FILE" 2>/dev/null &
fi

exit 0
