#!/bin/bash
# 性能分析脚本
# 分析各子系统的性能指标，生成优化建议

set -e

# 颜色定义
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "=========================================="
echo "性能分析报告"
echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""

# 检查数据库连接
if [ -z "$DATABASE_URL" ]; then
    echo -e "${RED}错误: DATABASE_URL 环境变量未设置${NC}"
    exit 1
fi

# 1. 分析 API 性能
echo -e "${GREEN}[1/4] 分析 API 性能...${NC}"
echo "----------------------------------------"

psql "$DATABASE_URL" -c "
SELECT
    metric_name as endpoint,
    COUNT(*) as request_count,
    ROUND(AVG(metric_value)::numeric, 2) as avg_duration_ms,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY metric_value)::numeric, 2) as p95_duration_ms,
    ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY metric_value)::numeric, 2) as p99_duration_ms,
    ROUND(MAX(metric_value)::numeric, 2) as max_duration_ms
FROM performance_metrics
WHERE service = 'api'
    AND metric_type = 'api_call'
    AND created_at > NOW() - INTERVAL '24 hours'
GROUP BY metric_name
HAVING AVG(metric_value) > 1000
ORDER BY avg_duration_ms DESC
LIMIT 10;
" 2>/dev/null || echo "暂无 API 性能数据"

echo ""

# 2. 分析数据库性能
echo -e "${GREEN}[2/4] 分析数据库性能...${NC}"
echo "----------------------------------------"

# 检查是否启用了 pg_stat_statements
psql "$DATABASE_URL" -c "
SELECT EXISTS (
    SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements'
) as pg_stat_enabled;
" 2>/dev/null

# 查询慢查询
psql "$DATABASE_URL" -c "
SELECT
    LEFT(query, 100) as query_preview,
    calls,
    ROUND(mean_exec_time::numeric, 2) as avg_time_ms,
    ROUND(total_exec_time::numeric, 2) as total_time_ms,
    ROUND((100 * total_exec_time / SUM(total_exec_time) OVER ())::numeric, 2) as pct_total
FROM pg_stat_statements
WHERE mean_exec_time > 1000
ORDER BY mean_exec_time DESC
LIMIT 10;
" 2>/dev/null || echo "pg_stat_statements 未启用或暂无数据"

echo ""

# 3. 分析爬虫性能
echo -e "${GREEN}[3/4] 分析爬虫性能...${NC}"
echo "----------------------------------------"

psql "$DATABASE_URL" -c "
SELECT
    metric_name as spider_name,
    COUNT(*) as run_count,
    ROUND(AVG(metric_value)::numeric, 2) as avg_duration_seconds,
    ROUND(AVG((tags->>'items_count')::float)::numeric, 2) as avg_items,
    ROUND(AVG((tags->>'error_rate')::float * 100)::numeric, 2) as avg_error_rate_pct
FROM performance_metrics
WHERE service = 'spider'
    AND metric_type = 'spider_run'
    AND created_at > NOW() - INTERVAL '24 hours'
GROUP BY metric_name
ORDER BY avg_error_rate_pct DESC, avg_duration_seconds DESC
LIMIT 10;
" 2>/dev/null || echo "暂无爬虫性能数据"

echo ""

# 4. 分析前端性能
echo -e "${GREEN}[4/4] 分析前端性能...${NC}"
echo "----------------------------------------"

psql "$DATABASE_URL" -c "
SELECT
    metric_name as page_name,
    COUNT(*) as load_count,
    ROUND(AVG(metric_value)::numeric, 2) as avg_load_time_ms,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY metric_value)::numeric, 2) as p95_load_time_ms
FROM performance_metrics
WHERE service = 'client'
    AND metric_type = 'page_load'
    AND created_at > NOW() - INTERVAL '24 hours'
GROUP BY metric_name
HAVING AVG(metric_value) > 3000
ORDER BY avg_load_time_ms DESC
LIMIT 10;
" 2>/dev/null || echo "暂无前端性能数据"

echo ""
echo "=========================================="
echo -e "${GREEN}性能分析完成${NC}"
echo "=========================================="
echo ""

# 生成优化建议
echo -e "${YELLOW}优化建议:${NC}"
echo "1. API 响应时间 P95 > 1s 的接口需要优化"
echo "2. 数据库慢查询需要添加索引或优化 SQL"
echo "3. 爬虫错误率 > 10% 需要检查网络和解析逻辑"
echo "4. 前端页面加载时间 > 3s 需要优化资源加载"
echo ""
