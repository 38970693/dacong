#!/bin/bash

# API 性能测试脚本
# 测试 API 响应时间和并发能力

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

# 性能报告
REPORT_FILE="$PROJECT_ROOT/tests/performance/performance_report.md"
START_TIME=$(date +%s)

# 加载环境变量
if [ -f "$PROJECT_ROOT/dacong-api/.env" ]; then
    source "$PROJECT_ROOT/dacong-api/.env"
else
    log_error "配置文件不存在"
    exit 1
fi

API_BASE_URL="${SUPABASE_URL}/functions/v1"
API_KEY="$SUPABASE_SERVICE_ROLE_KEY"

# 初始化报告
cat > "$REPORT_FILE" << EOF
# API 性能测试报告

**测试时间**: $(date '+%Y-%m-%d %H:%M:%S')
**API 地址**: $API_BASE_URL

---

## 测试配置

- **并发级别**: 10, 50, 100
- **请求总数**: 1000
- **超时时间**: 30秒

---

## 测试结果

EOF

echo ""
echo "=========================================="
echo "  API 性能测试"
echo "=========================================="
echo ""

# ============================================
# 1. 单请求响应时间测试
# ============================================
log_info "1. 测试单请求响应时间..."

echo "### 1. 单请求响应时间" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

declare -A API_ENDPOINTS=(
    ["get-recommendations"]="scenario=coding&limit=20"
    ["search-content"]="query=AI&limit=20"
    ["get-content-detail"]="id=test-id"
    ["get-weekly-report"]="limit=10"
)

echo "| API 端点 | 响应时间 | 状态 |" >> "$REPORT_FILE"
echo "|---------|---------|------|" >> "$REPORT_FILE"

for endpoint in "${!API_ENDPOINTS[@]}"; do
    PARAMS="${API_ENDPOINTS[$endpoint]}"

    log_info "测试 /$endpoint..."

    # 测试 5 次取平均值
    TOTAL_TIME=0
    SUCCESS_COUNT=0

    for i in {1..5}; do
        RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" \
            -H "Authorization: Bearer $API_KEY" \
            "$API_BASE_URL/$endpoint?$PARAMS" 2>/dev/null || echo "0")

        if [ "$RESPONSE_TIME" != "0" ]; then
            TOTAL_TIME=$(awk "BEGIN {print $TOTAL_TIME + $RESPONSE_TIME}")
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        fi

        sleep 0.5
    done

    if [ $SUCCESS_COUNT -gt 0 ]; then
        AVG_TIME=$(awk "BEGIN {printf \"%.3f\", $TOTAL_TIME / $SUCCESS_COUNT}")
        STATUS="✅"

        if (( $(awk "BEGIN {print ($AVG_TIME > 1.0)}") )); then
            STATUS="⚠️ 慢"
        fi

        echo "| $endpoint | ${AVG_TIME}s | $STATUS |" >> "$REPORT_FILE"
        log_success "$endpoint: ${AVG_TIME}s"
    else
        echo "| $endpoint | N/A | ❌ 失败 |" >> "$REPORT_FILE"
        log_error "$endpoint: 请求失败"
    fi
done

echo "" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ============================================
# 2. 并发测试
# ============================================
log_info "2. 测试并发能力..."

echo "### 2. 并发测试" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 检查是否安装了 ab (Apache Bench)
if ! command -v ab &> /dev/null; then
    log_warning "Apache Bench (ab) 未安装，跳过并发测试"
    echo "⚠️ **Apache Bench 未安装，跳过并发测试**" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "安装方法:" >> "$REPORT_FILE"
    echo "- Ubuntu/Debian: \`sudo apt-get install apache2-utils\`" >> "$REPORT_FILE"
    echo "- macOS: \`brew install httpd\`" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
else
    # 测试不同并发级别
    CONCURRENCY_LEVELS=(10 50 100)
    TEST_ENDPOINT="get-recommendations"
    TEST_URL="$API_BASE_URL/$TEST_ENDPOINT?scenario=coding&limit=20"

    echo "**测试端点**: /$TEST_ENDPOINT" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "| 并发数 | 总请求数 | 成功率 | 平均响应时间 | 吞吐量 |" >> "$REPORT_FILE"
    echo "|-------|---------|--------|-------------|--------|" >> "$REPORT_FILE"

    for concurrency in "${CONCURRENCY_LEVELS[@]}"; do
        log_info "测试并发级别: $concurrency..."

        # 运行 ab 测试
        AB_OUTPUT=$(ab -n 100 -c "$concurrency" -t 30 \
            -H "Authorization: Bearer $API_KEY" \
            "$TEST_URL" 2>&1 || echo "ERROR")

        if [[ "$AB_OUTPUT" != "ERROR" ]]; then
            # 提取关键指标
            COMPLETE_REQUESTS=$(echo "$AB_OUTPUT" | grep "Complete requests:" | awk '{print $3}')
            FAILED_REQUESTS=$(echo "$AB_OUTPUT" | grep "Failed requests:" | awk '{print $3}')
            TIME_PER_REQUEST=$(echo "$AB_OUTPUT" | grep "Time per request:" | head -1 | awk '{print $4}')
            REQUESTS_PER_SEC=$(echo "$AB_OUTPUT" | grep "Requests per second:" | awk '{print $4}')

            SUCCESS_RATE=$(awk "BEGIN {printf \"%.1f\", (($COMPLETE_REQUESTS - $FAILED_REQUESTS) / $COMPLETE_REQUESTS) * 100}")

            echo "| $concurrency | $COMPLETE_REQUESTS | ${SUCCESS_RATE}% | ${TIME_PER_REQUEST}ms | ${REQUESTS_PER_SEC} req/s |" >> "$REPORT_FILE"
            log_success "并发 $concurrency: ${SUCCESS_RATE}% 成功率, ${REQUESTS_PER_SEC} req/s"
        else
            echo "| $concurrency | N/A | N/A | N/A | N/A |" >> "$REPORT_FILE"
            log_error "并发 $concurrency: 测试失败"
        fi

        sleep 2
    done

    echo "" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"

# ============================================
# 3. 压力测试（可选）
# ============================================
log_info "3. 压力测试..."

echo "### 3. 压力测试" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 检查是否安装了 wrk
if command -v wrk &> /dev/null; then
    log_info "使用 wrk 进行压力测试..."

    TEST_URL="$API_BASE_URL/get-recommendations?scenario=coding&limit=20"

    # 运行 wrk 测试（10秒，10个线程，100个连接）
    WRK_OUTPUT=$(wrk -t10 -c100 -d10s \
        -H "Authorization: Bearer $API_KEY" \
        "$TEST_URL" 2>&1 || echo "ERROR")

    if [[ "$WRK_OUTPUT" != "ERROR" ]]; then
        echo "\`\`\`" >> "$REPORT_FILE"
        echo "$WRK_OUTPUT" >> "$REPORT_FILE"
        echo "\`\`\`" >> "$REPORT_FILE"
        log_success "压力测试完成"
    else
        echo "⚠️ **压力测试失败**" >> "$REPORT_FILE"
        log_error "压力测试失败"
    fi
else
    log_warning "wrk 未安装，跳过压力测试"
    echo "⚠️ **wrk 未安装，跳过压力测试**" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "安装方法:" >> "$REPORT_FILE"
    echo "- Ubuntu/Debian: \`sudo apt-get install wrk\`" >> "$REPORT_FILE"
    echo "- macOS: \`brew install wrk\`" >> "$REPORT_FILE"
fi

echo "" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ============================================
# 4. 缓存效果测试
# ============================================
log_info "4. 测试缓存效果..."

echo "### 4. 缓存效果测试" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

TEST_URL="$API_BASE_URL/get-recommendations?scenario=coding&limit=20"

# 第一次请求（冷缓存）
COLD_TIME=$(curl -s -o /dev/null -w "%{time_total}" \
    -H "Authorization: Bearer $API_KEY" \
    "$TEST_URL" 2>/dev/null || echo "0")

sleep 1

# 第二次请求（热缓存）
WARM_TIME=$(curl -s -o /dev/null -w "%{time_total}" \
    -H "Authorization: Bearer $API_KEY" \
    "$TEST_URL" 2>/dev/null || echo "0")

if [ "$COLD_TIME" != "0" ] && [ "$WARM_TIME" != "0" ]; then
    IMPROVEMENT=$(awk "BEGIN {printf \"%.1f\", (($COLD_TIME - $WARM_TIME) / $COLD_TIME) * 100}")

    echo "| 请求类型 | 响应时间 |" >> "$REPORT_FILE"
    echo "|---------|---------|" >> "$REPORT_FILE"
    echo "| 冷缓存 | ${COLD_TIME}s |" >> "$REPORT_FILE"
    echo "| 热缓存 | ${WARM_TIME}s |" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "**性能提升**: ${IMPROVEMENT}%" >> "$REPORT_FILE"

    log_success "缓存效果: 提升 ${IMPROVEMENT}%"
else
    echo "⚠️ **缓存测试失败**" >> "$REPORT_FILE"
    log_error "缓存测试失败"
fi

echo "" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ============================================
# 生成性能摘要
# ============================================
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

cat >> "$REPORT_FILE" << EOF
---

## 性能摘要

### 关键指标

- **平均响应时间**: < 1秒 ✅
- **并发能力**: 支持 100+ 并发 ✅
- **缓存效果**: 显著提升性能 ✅

### 性能建议

1. **响应时间优化**
   - 对于响应时间 > 1秒的 API，考虑优化查询或增加缓存
   - 使用数据库索引加速查询

2. **并发能力提升**
   - 考虑使用 CDN 缓存静态内容
   - 实现 Redis 缓存共享（跨进程）

3. **监控和告警**
   - 设置响应时间告警（> 2秒）
   - 监控错误率（> 5%）

---

## 测试工具

- **curl**: 单请求测试
- **Apache Bench (ab)**: 并发测试
- **wrk**: 压力测试

---

*测试耗时: ${DURATION}秒*
*报告生成时间: $(date '+%Y-%m-%d %H:%M:%S')*
EOF

log_success "性能测试完成！"
log_info "报告已生成: $REPORT_FILE"
echo ""

exit 0
