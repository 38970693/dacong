#!/bin/bash
# 密钥轮换脚本
# 用途：安全地轮换各类 API 密钥和服务密钥
# 使用：./rotate_keys.sh --service <service_name> [--backup-dir <dir>]

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"
BACKUP_DIR="${BACKUP_DIR:-$PROJECT_ROOT/.env.backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

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
密钥轮换脚本

用法:
    $0 --service <service_name> [options]
    $0 --all [options]

服务类型:
    supabase       轮换 Supabase 密钥
    github         轮换 GitHub Token
    openrouter     轮换 OpenRouter API Key
    jwt            轮换 JWT 密钥
    all            轮换所有密钥

选项:
    --backup-dir <dir>    指定备份目录 (默认: .env.backups)
    --no-backup           不备份旧密钥
    --verify              轮换后验证新密钥
    --help                显示此帮助信息

示例:
    $0 --service supabase --verify
    $0 --service github --backup-dir /tmp/backups
    $0 --all --verify

EOF
    exit 1
}

# 备份当前 .env 文件
backup_env() {
    if [[ ! -f "$ENV_FILE" ]]; then
        log_error ".env 文件不存在: $ENV_FILE"
        exit 1
    fi

    mkdir -p "$BACKUP_DIR"
    local backup_file="$BACKUP_DIR/.env.backup.$TIMESTAMP"

    cp "$ENV_FILE" "$backup_file"
    log_info "已备份 .env 到: $backup_file"

    # 只保留最近 10 个备份
    ls -t "$BACKUP_DIR"/.env.backup.* 2>/dev/null | tail -n +11 | xargs -r rm
}

# 生成随机密钥
generate_random_key() {
    local length=${1:-64}
    openssl rand -base64 "$length" | tr -d '\n'
}

# 更新 .env 文件中的密钥
update_env_key() {
    local key_name=$1
    local new_value=$2

    if grep -q "^${key_name}=" "$ENV_FILE"; then
        # 密钥存在，更新
        sed -i.tmp "s|^${key_name}=.*|${key_name}=${new_value}|" "$ENV_FILE"
        rm -f "${ENV_FILE}.tmp"
        log_info "已更新密钥: $key_name"
    else
        # 密钥不存在，追加
        echo "${key_name}=${new_value}" >> "$ENV_FILE"
        log_info "已添加密钥: $key_name"
    fi
}

# 轮换 Supabase 密钥
rotate_supabase() {
    log_info "开始轮换 Supabase 密钥..."

    log_warn "注意: Supabase 密钥需要在 Supabase Dashboard 手动重新生成"
    log_warn "步骤:"
    log_warn "  1. 访问 https://supabase.com/dashboard/project/<your-project>/settings/api"
    log_warn "  2. 点击 'Reset' 按钮重新生成密钥"
    log_warn "  3. 复制新密钥并粘贴到下方"

    echo ""
    read -p "请输入新的 SUPABASE_ANON_KEY: " new_anon_key
    read -p "请输入新的 SUPABASE_SERVICE_ROLE_KEY: " new_service_key

    if [[ -n "$new_anon_key" ]]; then
        update_env_key "SUPABASE_ANON_KEY" "$new_anon_key"
    fi

    if [[ -n "$new_service_key" ]]; then
        update_env_key "SUPABASE_SERVICE_ROLE_KEY" "$new_service_key"
    fi

    log_info "Supabase 密钥轮换完成"
}

# 轮换 GitHub Token
rotate_github() {
    log_info "开始轮换 GitHub Token..."

    log_warn "注意: GitHub Token 需要在 GitHub 手动重新生成"
    log_warn "步骤:"
    log_warn "  1. 访问 https://github.com/settings/tokens"
    log_warn "  2. 点击 'Generate new token' (classic)"
    log_warn "  3. 选择所需权限: repo, read:org"
    log_warn "  4. 复制新 token 并粘贴到下方"

    echo ""
    read -p "请输入新的 GITHUB_TOKEN: " new_token

    if [[ -n "$new_token" ]]; then
        update_env_key "GITHUB_TOKEN" "$new_token"
        log_info "GitHub Token 轮换完成"
    else
        log_warn "未输入新 token，跳过"
    fi
}

# 轮换 OpenRouter API Key
rotate_openrouter() {
    log_info "开始轮换 OpenRouter API Key..."

    log_warn "注意: OpenRouter API Key 需要在 OpenRouter 手动重新生成"
    log_warn "步骤:"
    log_warn "  1. 访问 https://openrouter.ai/keys"
    log_warn "  2. 点击 'Create Key' 生成新密钥"
    log_warn "  3. 复制新密钥并粘贴到下方"

    echo ""
    read -p "请输入新的 OPENROUTER_API_KEY: " new_key

    if [[ -n "$new_key" ]]; then
        update_env_key "OPENROUTER_API_KEY" "$new_key"
        log_info "OpenRouter API Key 轮换完成"
    else
        log_warn "未输入新密钥，跳过"
    fi
}

# 轮换 JWT 密钥
rotate_jwt() {
    log_info "开始轮换 JWT 密钥..."

    local new_secret=$(generate_random_key 64)
    update_env_key "JWT_SECRET" "$new_secret"

    log_warn "警告: JWT 密钥已更新，所有现有 token 将失效"
    log_warn "用户需要重新登录"
    log_info "JWT 密钥轮换完成"
}

# 验证密钥
verify_keys() {
    log_info "开始验证密钥..."

    # 验证 Supabase 连接
    if [[ -n "${SUPABASE_URL:-}" ]] && [[ -n "${SUPABASE_ANON_KEY:-}" ]]; then
        log_info "验证 Supabase 连接..."
        if curl -s -f -H "apikey: $SUPABASE_ANON_KEY" "$SUPABASE_URL/rest/v1/" > /dev/null; then
            log_info "✓ Supabase 连接正常"
        else
            log_error "✗ Supabase 连接失败"
        fi
    fi

    # 验证 GitHub Token
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        log_info "验证 GitHub Token..."
        if curl -s -f -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user > /dev/null; then
            log_info "✓ GitHub Token 有效"
        else
            log_error "✗ GitHub Token 无效"
        fi
    fi

    log_info "密钥验证完成"
}

# 主函数
main() {
    local service=""
    local do_backup=true
    local do_verify=false

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --service)
                service="$2"
                shift 2
                ;;
            --all)
                service="all"
                shift
                ;;
            --backup-dir)
                BACKUP_DIR="$2"
                shift 2
                ;;
            --no-backup)
                do_backup=false
                shift
                ;;
            --verify)
                do_verify=true
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

    if [[ -z "$service" ]]; then
        log_error "必须指定 --service 或 --all"
        usage
    fi

    # 备份
    if [[ "$do_backup" == true ]]; then
        backup_env
    fi

    # 加载当前环境变量
    if [[ -f "$ENV_FILE" ]]; then
        set -a
        source "$ENV_FILE"
        set +a
    fi

    # 执行轮换
    case $service in
        supabase)
            rotate_supabase
            ;;
        github)
            rotate_github
            ;;
        openrouter)
            rotate_openrouter
            ;;
        jwt)
            rotate_jwt
            ;;
        all)
            rotate_supabase
            rotate_github
            rotate_openrouter
            rotate_jwt
            ;;
        *)
            log_error "不支持的服务: $service"
            usage
            ;;
    esac

    # 验证
    if [[ "$do_verify" == true ]]; then
        # 重新加载更新后的环境变量
        set -a
        source "$ENV_FILE"
        set +a
        verify_keys
    fi

    log_info "密钥轮换完成！"
    log_warn "请重启所有使用这些密钥的服务"
}

main "$@"
