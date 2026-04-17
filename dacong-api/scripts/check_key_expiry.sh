#!/bin/bash
# 密钥过期检查脚本
# 用途：检查密钥创建时间，计算剩余有效期，发送过期提醒
# 使用：./check_key_expiry.sh [--notify] [--report]

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KEY_METADATA_FILE="$PROJECT_ROOT/.env.key_metadata.json"

# 密钥有效期配置（天）
SUPABASE_KEY_EXPIRY=90
GITHUB_KEY_EXPIRY=180
OPENROUTER_KEY_EXPIRY=365
JWT_KEY_EXPIRY=90

# 提前提醒天数
WARNING_DAYS=14

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示使用说明
usage() {
    cat << EOF
密钥过期检查脚本

用法:
    $0 [options]

选项:
    --notify              发送过期提醒通知
    --report              生成详细报告
    --init                初始化密钥元数据文件
    --help                显示此帮助信息

示例:
    $0                    # 检查所有密钥
    $0 --notify           # 检查并发送通知
    $0 --report           # 生成详细报告

EOF
    exit 1
}

# 初始化密钥元数据文件
init_metadata() {
    log_info "初始化密钥元数据文件..."

    local current_date=$(date +%Y-%m-%d)

    cat > "$KEY_METADATA_FILE" << EOF
{
  "keys": {
    "SUPABASE_ANON_KEY": {
      "created_at": "$current_date",
      "expiry_days": $SUPABASE_KEY_EXPIRY,
      "last_rotated": "$current_date",
      "rotation_count": 0
    },
    "SUPABASE_SERVICE_ROLE_KEY": {
      "created_at": "$current_date",
      "expiry_days": $SUPABASE_KEY_EXPIRY,
      "last_rotated": "$current_date",
      "rotation_count": 0
    },
    "GITHUB_TOKEN": {
      "created_at": "$current_date",
      "expiry_days": $GITHUB_KEY_EXPIRY,
      "last_rotated": "$current_date",
      "rotation_count": 0
    },
    "OPENROUTER_API_KEY": {
      "created_at": "$current_date",
      "expiry_days": $OPENROUTER_KEY_EXPIRY,
      "last_rotated": "$current_date",
      "rotation_count": 0
    },
    "JWT_SECRET": {
      "created_at": "$current_date",
      "expiry_days": $JWT_KEY_EXPIRY,
      "last_rotated": "$current_date",
      "rotation_count": 0
    }
  },
  "last_check": "$current_date"
}
EOF

    log_info "密钥元数据文件已创建: $KEY_METADATA_FILE"
}

# 计算日期差（天）
date_diff() {
    local date1=$1
    local date2=$2

    local d1=$(date -d "$date1" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$date1" +%s)
    local d2=$(date -d "$date2" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$date2" +%s)

    echo $(( (d2 - d1) / 86400 ))
}

# 检查单个密钥
check_key() {
    local key_name=$1
    local created_at=$2
    local expiry_days=$3
    local current_date=$(date +%Y-%m-%d)

    local days_since_creation=$(date_diff "$created_at" "$current_date")
    local days_remaining=$((expiry_days - days_since_creation))

    local status="OK"
    local color=$GREEN

    if [[ $days_remaining -le 0 ]]; then
        status="EXPIRED"
        color=$RED
    elif [[ $days_remaining -le $WARNING_DAYS ]]; then
        status="WARNING"
        color=$YELLOW
    fi

    echo -e "${color}[$status]${NC} $key_name: $days_remaining 天后过期 (创建于 $created_at)"

    # 返回状态码
    if [[ "$status" == "EXPIRED" ]]; then
        return 2
    elif [[ "$status" == "WARNING" ]]; then
        return 1
    else
        return 0
    fi
}

# 检查所有密钥
check_all_keys() {
    if [[ ! -f "$KEY_METADATA_FILE" ]]; then
        log_error "密钥元数据文件不存在，请先运行: $0 --init"
        exit 1
    fi

    log_info "开始检查密钥过期状态..."
    echo ""

    local has_expired=false
    local has_warning=false

    # 使用 jq 解析 JSON（如果可用）
    if command -v jq &> /dev/null; then
        while IFS= read -r key_name; do
            local created_at=$(jq -r ".keys[\"$key_name\"].created_at" "$KEY_METADATA_FILE")
            local expiry_days=$(jq -r ".keys[\"$key_name\"].expiry_days" "$KEY_METADATA_FILE")

            if check_key "$key_name" "$created_at" "$expiry_days"; then
                :
            elif [[ $? -eq 1 ]]; then
                has_warning=true
            else
                has_expired=true
            fi
        done < <(jq -r '.keys | keys[]' "$KEY_METADATA_FILE")
    else
        log_warn "未安装 jq，使用简化检查"
        # 简化版本：假设所有密钥都是最近创建的
        log_info "所有密钥状态: OK (无法精确检查，请安装 jq)"
    fi

    echo ""

    if [[ "$has_expired" == true ]]; then
        log_error "发现已过期的密钥！请立即轮换"
        return 2
    elif [[ "$has_warning" == true ]]; then
        log_warn "部分密钥即将过期，建议尽快轮换"
        return 1
    else
        log_info "所有密钥状态正常"
        return 0
    fi
}

# 生成详细报告
generate_report() {
    log_info "生成密钥状态报告..."

    local report_file="$PROJECT_ROOT/key_status_report_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "================================"
        echo "密钥状态报告"
        echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "================================"
        echo ""

        if [[ -f "$KEY_METADATA_FILE" ]]; then
            if command -v jq &> /dev/null; then
                while IFS= read -r key_name; do
                    local created_at=$(jq -r ".keys[\"$key_name\"].created_at" "$KEY_METADATA_FILE")
                    local expiry_days=$(jq -r ".keys[\"$key_name\"].expiry_days" "$KEY_METADATA_FILE")
                    local last_rotated=$(jq -r ".keys[\"$key_name\"].last_rotated" "$KEY_METADATA_FILE")
                    local rotation_count=$(jq -r ".keys[\"$key_name\"].rotation_count" "$KEY_METADATA_FILE")

                    local current_date=$(date +%Y-%m-%d)
                    local days_since_creation=$(date_diff "$created_at" "$current_date")
                    local days_remaining=$((expiry_days - days_since_creation))

                    echo "密钥: $key_name"
                    echo "  创建时间: $created_at"
                    echo "  有效期: $expiry_days 天"
                    echo "  已使用: $days_since_creation 天"
                    echo "  剩余: $days_remaining 天"
                    echo "  上次轮换: $last_rotated"
                    echo "  轮换次数: $rotation_count"
                    echo ""
                done < <(jq -r '.keys | keys[]' "$KEY_METADATA_FILE")
            else
                echo "错误: 需要安装 jq 才能生成详细报告"
            fi
        else
            echo "错误: 密钥元数据文件不存在"
        fi

        echo "================================"
    } > "$report_file"

    log_info "报告已生成: $report_file"
    cat "$report_file"
}

# 发送通知（示例：可扩展为邮件/Slack/钉钉）
send_notification() {
    local message=$1

    log_info "发送通知: $message"

    # TODO: 集成实际的通知服务
    # 示例：
    # - 邮件: echo "$message" | mail -s "密钥过期提醒" admin@example.com
    # - Slack: curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$message\"}" $SLACK_WEBHOOK_URL
    # - 钉钉: curl -X POST -H 'Content-Type: application/json' -d "{\"msgtype\":\"text\",\"text\":{\"content\":\"$message\"}}" $DINGTALK_WEBHOOK_URL

    log_warn "通知功能未配置，请在脚本中添加通知集成"
}

# 主函数
main() {
    local do_notify=false
    local do_report=false
    local do_init=false

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --notify)
                do_notify=true
                shift
                ;;
            --report)
                do_report=true
                shift
                ;;
            --init)
                do_init=true
                shift
                ;;
            --help)
                usage
                ;;
            *)
                log_error "未知参数: $1"
                usage
                ;;
        esac
    done

    # 初始化
    if [[ "$do_init" == true ]]; then
        init_metadata
        exit 0
    fi

    # 检查密钥
    if check_all_keys; then
        status="所有密钥状态正常"
        exit_code=0
    elif [[ $? -eq 1 ]]; then
        status="部分密钥即将过期"
        exit_code=1
    else
        status="发现已过期的密钥"
        exit_code=2
    fi

    # 发送通知
    if [[ "$do_notify" == true ]]; then
        send_notification "$status"
    fi

    # 生成报告
    if [[ "$do_report" == true ]]; then
        generate_report
    fi

    exit $exit_code
}

main "$@"
