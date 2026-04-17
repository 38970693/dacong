#!/bin/bash

# 系统健康检查脚本
# 检查数据库、API、爬虫状态和数据完整性

set -e

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

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# 健康状态
HEALTH_STATUS="HEALTHY"
ISSUES=()

echo ""
echo "=========================================="
echo "  DaCong 系统健康检查"
echo "=========================================="
echo ""
echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# ============================================
# 1. 环境配置检查
# ============================================
log_info "1. 检查环境配置..."

if [ -f "$PROJECT_ROOT/dacong-api/.env" ]; then
    source "$PROJECT_ROOT/dacong-api/.env"

    if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_SERVICE_ROLE_KEY" ]; then
        log_success "Supabase 配置正常"
    else
        log_error "Supabase 配置不完整"
        HEALTH_STATUS="UNHEALTHY"
        ISSUES+=("Supabase 配置缺失")
    fi
else
    log_error "配置文件不存在: dacong-api/.env"
    HEALTH_STATUS="UNHEALTHY"
    ISSUES+=("配置文件缺失")
fi

echo ""

# ============================================
# 2. 数据库连接检查
# ============================================
log_info "2. 检查数据库连接..."

DB_CHECK=$(cd "$PROJECT_ROOT/dacong-api" && deno eval "
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') || '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
);

try {
  const { data, error } = await supabase.from('published_content').select('count').limit(1);
  if (error) throw error;
  console.log('OK');
} catch (e) {
  console.log('ERROR:', e.message);
}
" 2>&1)

if [[ "$DB_CHECK" == *"OK"* ]]; then
    log_success "数据库连接正常"
else
    log_error "数据库连接失败: $DB_CHECK"
    HEALTH_STATUS="UNHEALTHY"
    ISSUES+=("数据库连接失败")
fi

echo ""

# ============================================
# 3. API 端点检查
# ============================================
log_info "3. 检查 API 端点..."

API_BASE_URL="${SUPABASE_URL}/functions/v1"
API_KEY="$SUPABASE_SERVICE_ROLE_KEY"

# 检查各个 API 端点
declare -A API_ENDPOINTS=(
    ["get-recommendations"]="scenario=coding&limit=5"
    ["search-content"]="query=AI&limit=5"
    ["get-weekly-report"]="limit=5"
)

API_HEALTHY=true

for endpoint in "${!API_ENDPOINTS[@]}"; do
    PARAMS="${API_ENDPOINTS[$endpoint]}"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $API_KEY" \
        "$API_BASE_URL/$endpoint?$PARAMS" 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ]; then
        log_success "API /$endpoint 正常 (HTTP $HTTP_CODE)"
    else
        log_error "API /$endpoint 异常 (HTTP $HTTP_CODE)"
        API_HEALTHY=false
        ISSUES+=("API $endpoint 不可用")
    fi
done

if [ "$API_HEALTHY" = false ]; then
    HEALTH_STATUS="DEGRADED"
fi

echo ""

# ============================================
# 4. 爬虫状态检查
# ============================================
log_info "4. 检查爬虫状态..."

if [ -f "$PROJECT_ROOT/dacong-spider/.env" ]; then
    cd "$PROJECT_ROOT/dacong-spider"

    # 检查爬虫配置
    if python3 main.py --validate-config > /tmp/spider_config.log 2>&1; then
        log_success "爬虫配置有效"
    else
        log_warning "爬虫配置可能有问题"
        HEALTH_STATUS="DEGRADED"
        ISSUES+=("爬虫配置异常")
    fi

    # 检查最近的爬虫日志
    if [ -f "logs/dacong_spider.log" ]; then
        RECENT_ERRORS=$(tail -100 logs/dacong_spider.log | grep -c "ERROR" || echo "0")
        if [ "$RECENT_ERRORS" -gt 10 ]; then
            log_warning "最近有 $RECENT_ERRORS 个错误日志"
            HEALTH_STATUS="DEGRADED"
            ISSUES+=("爬虫错误较多")
        else
            log_success "爬虫日志正常 (最近 $RECENT_ERRORS 个错误)"
        fi
    else
        log_warning "爬虫日志文件不存在"
    fi
else
    log_warning "爬虫配置文件不存在"
    HEALTH_STATUS="DEGRADED"
    ISSUES+=("爬虫未配置")
fi

echo ""

# ============================================
# 5. 数据完整性检查
# ============================================
log_info "5. 检查数据完整性..."

DATA_CHECK=$(cd "$PROJECT_ROOT/dacong-api" && deno eval "
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') || '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
);

const tables = [
  'raw_data',
  'generated_content',
  'published_content',
  'user_feedback',
  'spider_logs'
];

const results = {};

for (const table of tables) {
  try {
    const { count, error } = await supabase
      .from(table)
      .select('*', { count: 'exact', head: true });

    results[table] = { count: count || 0, status: error ? 'ERROR' : 'OK' };
  } catch (e) {
    results[table] = { count: 0, status: 'ERROR' };
  }
}

console.log(JSON.stringify(results, null, 2));
" 2>&1)

if echo "$DATA_CHECK" | grep -q "count"; then
    echo "$DATA_CHECK" | while IFS= read -r line; do
        if [[ "$line" == *"raw_data"* ]]; then
            COUNT=$(echo "$line" | grep -oP '(?<="count": )\d+')
            if [ "$COUNT" -gt 0 ]; then
                log_success "raw_data: $COUNT 条记录"
            else
                log_warning "raw_data: 无数据"
            fi
        elif [[ "$line" == *"published_content"* ]]; then
            COUNT=$(echo "$line" | grep -oP '(?<="count": )\d+')
            if [ "$COUNT" -gt 0 ]; then
                log_success "published_content: $COUNT 条记录"
            else
                log_warning "published_content: 无数据"
                HEALTH_STATUS="DEGRADED"
                ISSUES+=("已发布内容为空")
            fi
        fi
    done
else
    log_error "数据完整性检查失败"
    HEALTH_STATUS="UNHEALTHY"
    ISSUES+=("数据查询失败")
fi

echo ""

# ============================================
# 6. 磁盘空间检查
# ============================================
log_info "6. 检查磁盘空间..."

DISK_USAGE=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//')

if [ "$DISK_USAGE" -lt 80 ]; then
    log_success "磁盘空间充足 (已使用 ${DISK_USAGE}%)"
elif [ "$DISK_USAGE" -lt 90 ]; then
    log_warning "磁盘空间不足 (已使用 ${DISK_USAGE}%)"
    HEALTH_STATUS="DEGRADED"
    ISSUES+=("磁盘空间不足")
else
    log_error "磁盘空间严重不足 (已使用 ${DISK_USAGE}%)"
    HEALTH_STATUS="UNHEALTHY"
    ISSUES+=("磁盘空间严重不足")
fi

echo ""

# ============================================
# 7. 日志文件检查
# ============================================
log_info "7. 检查日志文件..."

# 检查日志文件大小
if [ -f "$PROJECT_ROOT/dacong-spider/logs/dacong_spider.log" ]; then
    LOG_SIZE=$(du -h "$PROJECT_ROOT/dacong-spider/logs/dacong_spider.log" | cut -f1)
    log_success "爬虫日志大小: $LOG_SIZE"

    # 如果日志文件超过 100MB，建议清理
    LOG_SIZE_MB=$(du -m "$PROJECT_ROOT/dacong-spider/logs/dacong_spider.log" | cut -f1)
    if [ "$LOG_SIZE_MB" -gt 100 ]; then
        log_warning "日志文件较大，建议清理"
    fi
fi

echo ""

# ============================================
# 生成健康报告
# ============================================
echo "=========================================="
echo "  健康检查摘要"
echo "=========================================="
echo ""

case "$HEALTH_STATUS" in
    "HEALTHY")
        echo -e "${GREEN}状态: ✓ 健康${NC}"
        ;;
    "DEGRADED")
        echo -e "${YELLOW}状态: ! 降级${NC}"
        ;;
    "UNHEALTHY")
        echo -e "${RED}状态: ✗ 不健康${NC}"
        ;;
esac

echo ""

if [ ${#ISSUES[@]} -gt 0 ]; then
    echo "发现的问题:"
    for issue in "${ISSUES[@]}"; do
        echo "  - $issue"
    done
    echo ""
fi

echo "检查完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 返回状态码
case "$HEALTH_STATUS" in
    "HEALTHY")
        exit 0
        ;;
    "DEGRADED")
        exit 1
        ;;
    "UNHEALTHY")
        exit 2
        ;;
esac
