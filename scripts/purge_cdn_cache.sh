#!/bin/bash
# Cloudflare CDN 缓存刷新脚本
#
# 用法：
#   ./scripts/purge_cdn_cache.sh                    # 刷新所有缓存
#   ./scripts/purge_cdn_cache.sh --files "url1,url2" # 刷新特定文件
#   ./scripts/purge_cdn_cache.sh --prefix "/images/" # 刷新特定路径前缀
#   ./scripts/purge_cdn_cache.sh --tags "tag1,tag2"  # 刷新特定标签

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# 检查环境变量
check_env() {
    if [ -z "$CLOUDFLARE_ZONE_ID" ]; then
        log_error "环境变量 CLOUDFLARE_ZONE_ID 未设置"
        log_info "请在 .env 文件中配置或执行："
        log_info "export CLOUDFLARE_ZONE_ID=your-zone-id"
        exit 1
    fi

    if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
        log_error "环境变量 CLOUDFLARE_API_TOKEN 未设置"
        log_info "请在 .env 文件中配置或执行："
        log_info "export CLOUDFLARE_API_TOKEN=your-api-token"
        exit 1
    fi
}

# 加载 .env 文件
load_env() {
    if [ -f .env ]; then
        log_info "加载 .env 文件..."
        export $(grep -v '^#' .env | xargs)
    fi
}

# 刷新所有缓存
purge_all() {
    log_info "正在刷新所有 CDN 缓存..."

    response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data '{"purge_everything":true}')

    check_response "$response"
}

# 刷新特定文件
purge_files() {
    local files=$1
    log_info "正在刷新指定文件的缓存..."

    # 将逗号分隔的字符串转换为 JSON 数组
    local files_json=$(echo "$files" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$";""))')

    response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"files\":$files_json}")

    check_response "$response"
}

# 刷新特定路径前缀
purge_prefix() {
    local prefix=$1
    log_info "正在刷新路径前缀 '$prefix' 的缓存..."

    # 将逗号分隔的字符串转换为 JSON 数组
    local prefixes_json=$(echo "$prefix" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$";""))')

    response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"prefixes\":$prefixes_json}")

    check_response "$response"
}

# 刷新特定标签
purge_tags() {
    local tags=$1
    log_info "正在刷新标签 '$tags' 的缓存..."

    # 将逗号分隔的字符串转换为 JSON 数组
    local tags_json=$(echo "$tags" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$";""))')

    response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"tags\":$tags_json}")

    check_response "$response"
}

# 检查 API 响应
check_response() {
    local response=$1

    # 检查是否成功
    local success=$(echo "$response" | jq -r '.success')

    if [ "$success" = "true" ]; then
        log_info "✓ CDN 缓存刷新成功"

        # 显示详细信息
        local id=$(echo "$response" | jq -r '.result.id // empty')
        if [ -n "$id" ]; then
            log_info "刷新 ID: $id"
        fi
    else
        log_error "✗ CDN 缓存刷新失败"

        # 显示错误信息
        local errors=$(echo "$response" | jq -r '.errors[]? | "  - [\(.code)] \(.message)"')
        if [ -n "$errors" ]; then
            log_error "错误详情："
            echo "$errors"
        else
            log_error "响应: $response"
        fi

        exit 1
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
Cloudflare CDN 缓存刷新脚本

用法:
  $0 [选项]

选项:
  无参数              刷新所有缓存
  --files <urls>      刷新特定文件（逗号分隔的 URL 列表）
  --prefix <paths>    刷新特定路径前缀（逗号分隔）
  --tags <tags>       刷新特定标签（逗号分隔，需要 Enterprise 计划）
  -h, --help          显示此帮助信息

环境变量:
  CLOUDFLARE_ZONE_ID      Cloudflare Zone ID（必需）
  CLOUDFLARE_API_TOKEN    Cloudflare API Token（必需）

示例:
  # 刷新所有缓存
  $0

  # 刷新特定文件
  $0 --files "https://cdn.dacong.ai/images/logo.png,https://cdn.dacong.ai/css/style.css"

  # 刷新特定路径
  $0 --prefix "/images/,/css/"

  # 刷新特定标签
  $0 --tags "production,v1.2.3"

注意:
  - 刷新所有缓存会影响整个站点，请谨慎使用
  - 刷新特定文件最多支持 30 个 URL
  - 刷新路径前缀需要 Enterprise 计划
  - 刷新标签需要 Enterprise 计划

EOF
}

# 主函数
main() {
    # 检查 jq 是否安装
    if ! command -v jq &> /dev/null; then
        log_error "jq 未安装，请先安装 jq"
        log_info "Ubuntu/Debian: sudo apt-get install jq"
        log_info "macOS: brew install jq"
        log_info "Windows: choco install jq"
        exit 1
    fi

    # 加载环境变量
    load_env

    # 检查环境变量
    check_env

    # 解析参数
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        --files)
            if [ -z "${2:-}" ]; then
                log_error "请提供要刷新的文件 URL"
                show_help
                exit 1
            fi
            purge_files "$2"
            ;;
        --prefix)
            if [ -z "${2:-}" ]; then
                log_error "请提供要刷新的路径前缀"
                show_help
                exit 1
            fi
            purge_prefix "$2"
            ;;
        --tags)
            if [ -z "${2:-}" ]; then
                log_error "请提供要刷新的标签"
                show_help
                exit 1
            fi
            purge_tags "$2"
            ;;
        "")
            # 无参数，刷新所有缓存
            log_warn "即将刷新所有 CDN 缓存，这会影响整个站点"
            read -p "确认继续？(y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                purge_all
            else
                log_info "已取消"
                exit 0
            fi
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac

    log_info "完成！"
}

# 执行主函数
main "$@"
