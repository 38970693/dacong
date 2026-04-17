#!/bin/bash
# Redis 缓存监控脚本
# 实时监控 Redis 缓存性能和状态

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
REDIS_HOST="${REDIS_HOST:-localhost}"
REDIS_PORT="${REDIS_PORT:-6379}"
REDIS_PASSWORD="${REDIS_PASSWORD:-}"
REFRESH_INTERVAL="${REFRESH_INTERVAL:-5}"

# Redis CLI 命令
if [ -n "$REDIS_PASSWORD" ]; then
    REDIS_CMD="redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD"
else
    REDIS_CMD="redis-cli -h $REDIS_HOST -p $REDIS_PORT"
fi

# 清屏函数
clear_screen() {
    clear
}

# 获取 Redis 统计信息
get_redis_stats() {
    $REDIS_CMD INFO stats
}

# 获取 Redis 内存信息
get_redis_memory() {
    $REDIS_CMD INFO memory
}

# 获取数据库大小
get_dbsize() {
    $REDIS_CMD DBSIZE
}

# 计算命中率
calculate_hit_rate() {
    local stats=$(get_redis_stats)
    local hits=$(echo "$stats" | grep "keyspace_hits:" | cut -d: -f2 | tr -d '\r')
    local misses=$(echo "$stats" | grep "keyspace_misses:" | cut -d: -f2 | tr -d '\r')

    if [ -z "$hits" ] || [ -z "$misses" ]; then
        echo "0.00"
        return
    fi

    local total=$((hits + misses))
    if [ $total -eq 0 ]; then
        echo "0.00"
    else
        echo "scale=2; $hits * 100 / $total" | bc
    fi
}

# 格式化字节数
format_bytes() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes}B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$(echo "scale=2; $bytes / 1024" | bc)KB"
    elif [ $bytes -lt 1073741824 ]; then
        echo "$(echo "scale=2; $bytes / 1048576" | bc)MB"
    else
        echo "$(echo "scale=2; $bytes / 1073741824" | bc)GB"
    fi
}

# 显示监控面板
show_dashboard() {
    clear_screen

    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           Redis 缓存监控面板                               ║${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC} 服务器: $REDIS_HOST:$REDIS_PORT"
    echo -e "${BLUE}║${NC} 刷新间隔: ${REFRESH_INTERVAL}s"
    echo -e "${BLUE}║${NC} 时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # 获取统计信息
    local stats=$(get_redis_stats)
    local memory=$(get_redis_memory)
    local dbsize=$(get_dbsize)

    # 解析数据
    local hits=$(echo "$stats" | grep "keyspace_hits:" | cut -d: -f2 | tr -d '\r')
    local misses=$(echo "$stats" | grep "keyspace_misses:" | cut -d: -f2 | tr -d '\r')
    local hit_rate=$(calculate_hit_rate)
    local used_memory=$(echo "$memory" | grep "used_memory:" | head -1 | cut -d: -f2 | tr -d '\r')
    local used_memory_human=$(echo "$memory" | grep "used_memory_human:" | cut -d: -f2 | tr -d '\r')
    local mem_fragmentation=$(echo "$memory" | grep "mem_fragmentation_ratio:" | cut -d: -f2 | tr -d '\r')

    # 显示缓存统计
    echo -e "${GREEN}=== 缓存统计 ===${NC}"
    echo -e "  总键数:        ${YELLOW}$dbsize${NC}"
    echo -e "  命中次数:      ${GREEN}$hits${NC}"
    echo -e "  未命中次数:    ${RED}$misses${NC}"
    echo -e "  命中率:        ${YELLOW}${hit_rate}%${NC}"

    # 命中率颜色提示
    if (( $(echo "$hit_rate >= 80" | bc -l) )); then
        echo -e "  状态:          ${GREEN}✓ 优秀${NC}"
    elif (( $(echo "$hit_rate >= 60" | bc -l) )); then
        echo -e "  状态:          ${YELLOW}⚠ 良好${NC}"
    else
        echo -e "  状态:          ${RED}✗ 需要优化${NC}"
    fi

    echo ""

    # 显示内存使用
    echo -e "${GREEN}=== 内存使用 ===${NC}"
    echo -e "  已用内存:      ${YELLOW}$used_memory_human${NC}"
    echo -e "  内存碎片率:    ${YELLOW}$mem_fragmentation${NC}"

    echo ""

    # 显示热键（Top 10）
    echo -e "${GREEN}=== 热键 Top 10 ===${NC}"
    $REDIS_CMD --scan --pattern '*' | head -10 | while read key; do
        local ttl=$($REDIS_CMD TTL "$key")
        if [ "$ttl" = "-1" ]; then
            echo -e "  ${BLUE}$key${NC} (永久)"
        elif [ "$ttl" = "-2" ]; then
            echo -e "  ${RED}$key${NC} (已过期)"
        else
            echo -e "  ${BLUE}$key${NC} (TTL: ${ttl}s)"
        fi
    done

    echo ""
    echo -e "${YELLOW}按 Ctrl+C 退出监控${NC}"
}

# 主循环
main() {
    echo -e "${GREEN}正在连接到 Redis...${NC}"

    # 检查连接
    if ! $REDIS_CMD ping > /dev/null 2>&1; then
        echo -e "${RED}错误: 无法连接到 Redis${NC}"
        exit 1
    fi

    echo -e "${GREEN}连接成功！${NC}"
    sleep 1

    # 监控循环
    while true; do
        show_dashboard
        sleep $REFRESH_INTERVAL
    done
}

# 捕获 Ctrl+C
trap 'echo -e "\n${GREEN}监控已停止${NC}"; exit 0' INT

# 运行
main
