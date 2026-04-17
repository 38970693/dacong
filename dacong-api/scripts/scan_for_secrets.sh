#!/bin/bash
# 密钥泄露扫描脚本
# 用途：扫描代码库中的硬编码密钥、敏感信息
# 使用：./scan_for_secrets.sh [--fix] [--report]

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

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
密钥泄露扫描脚本

用法:
    $0 [options]

选项:
    --report              生成详细报告
    --ci                  CI 模式（发现问题返回非零退出码）
    --help                显示此帮助信息

示例:
    $0                    # 扫描所有文件
    $0 --report           # 生成详细报告
    $0 --ci               # CI 模式

EOF
    exit 1
}

# 敏感信息正则模式
declare -A PATTERNS=(
    ["AWS Access Key"]="AKIA[0-9A-Z]{16}"
    ["AWS Secret Key"]="[0-9a-zA-Z/+=]{40}"
    ["GitHub Token"]="ghp_[0-9a-zA-Z]{36}"
    ["GitHub OAuth"]="gho_[0-9a-zA-Z]{36}"
    ["Slack Token"]="xox[baprs]-[0-9]{10,12}-[0-9]{10,12}-[0-9a-zA-Z]{24,32}"
    ["Slack Webhook"]="https://hooks\.slack\.com/services/T[a-zA-Z0-9_]{8}/B[a-zA-Z0-9_]{8}/[a-zA-Z0-9_]{24}"
    ["Private Key"]="-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----"
    ["Generic API Key"]="api[_-]?key['\"]?\s*[:=]\s*['\"][0-9a-zA-Z]{20,}['\"]"
    ["Generic Secret"]="secret['\"]?\s*[:=]\s*['\"][0-9a-zA-Z]{20,}['\"]"
    ["Password"]="password['\"]?\s*[:=]\s*['\"][^'\"]{8,}['\"]"
    ["JWT Token"]="eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}"
    ["Database URL"]="(postgres|mysql|mongodb)://[^:]+:[^@]+@[^/]+"
    ["Supabase Key"]="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+"
)

# 排除的文件和目录
EXCLUDE_PATTERNS=(
    "node_modules"
    ".git"
    "dist"
    "build"
    "*.min.js"
    "*.map"
    "package-lock.json"
    "yarn.lock"
    ".env.example"
    "*.md"
    "scan_for_secrets.sh"
)

# 构建 grep 排除参数
build_exclude_args() {
    local args=""
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        args="$args --exclude-dir=$pattern --exclude=$pattern"
    done
    echo "$args"
}

# 扫描单个模式
scan_pattern() {
    local pattern_name=$1
    local pattern=$2
    local found=false

    log_info "扫描: $pattern_name"

    local exclude_args=$(build_exclude_args)

    # 使用 grep 扫描
    if grep -rn -E $exclude_args "$pattern" "$PROJECT_ROOT" 2>/dev/null; then
        log_error "发现 $pattern_name"
        found=true
    fi

    if [[ "$found" == true ]]; then
        return 1
    else
        return 0
    fi
}

# 扫描所有模式
scan_all() {
    log_info "开始扫描密钥泄露..."
    echo ""

    local total_issues=0

    for pattern_name in "${!PATTERNS[@]}"; do
        if ! scan_pattern "$pattern_name" "${PATTERNS[$pattern_name]}"; then
            ((total_issues++))
        fi
        echo ""
    done

    echo "================================"
    if [[ $total_issues -eq 0 ]]; then
        log_info "✓ 未发现密钥泄露"
        return 0
    else
        log_error "✗ 发现 $total_issues 类敏感信息"
        return 1
    fi
}

# 检查 .env 文件是否被 git 跟踪
check_env_files() {
    log_info "检查 .env 文件..."

    local found_tracked=false

    while IFS= read -r file; do
        if git ls-files --error-unmatch "$file" &>/dev/null; then
            log_error "✗ .env 文件被 git 跟踪: $file"
            found_tracked=true
        fi
    done < <(find "$PROJECT_ROOT" -name ".env" -not -path "*/node_modules/*" -not -path "*/.git/*")

    if [[ "$found_tracked" == false ]]; then
        log_info "✓ 所有 .env 文件未被跟踪"
        return 0
    else
        log_error "请运行: git rm --cached <file> 移除跟踪"
        return 1
    fi
}

# 检查 .gitignore
check_gitignore() {
    log_info "检查 .gitignore..."

    local gitignore="$PROJECT_ROOT/.gitignore"

    if [[ ! -f "$gitignore" ]]; then
        log_error "✗ .gitignore 文件不存在"
        return 1
    fi

    local required_patterns=(
        ".env"
        ".env.local"
        ".env.*.local"
        "*.pem"
        "*.key"
        "*.p12"
        "*.pfx"
    )

    local missing=false

    for pattern in "${required_patterns[@]}"; do
        if ! grep -q "^$pattern$" "$gitignore"; then
            log_warn "✗ .gitignore 缺少: $pattern"
            missing=true
        fi
    done

    if [[ "$missing" == false ]]; then
        log_info "✓ .gitignore 配置正确"
        return 0
    else
        return 1
    fi
}

# 生成报告
generate_report() {
    log_info "生成扫描报告..."

    local report_file="$PROJECT_ROOT/security_scan_report_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "================================"
        echo "密钥泄露扫描报告"
        echo "生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "================================"
        echo ""

        echo "扫描范围: $PROJECT_ROOT"
        echo ""

        echo "扫描结果:"
        echo ""

        # 重新扫描并输出到报告
        for pattern_name in "${!PATTERNS[@]}"; do
            echo "[$pattern_name]"
            local exclude_args=$(build_exclude_args)
            if grep -rn -E $exclude_args "${PATTERNS[$pattern_name]}" "$PROJECT_ROOT" 2>/dev/null; then
                echo ""
            else
                echo "  未发现"
                echo ""
            fi
        done

        echo "================================"
        echo ".env 文件检查:"
        echo ""
        find "$PROJECT_ROOT" -name ".env" -not -path "*/node_modules/*" -not -path "*/.git/*" | while read -r file; do
            if git ls-files --error-unmatch "$file" &>/dev/null; then
                echo "  [TRACKED] $file"
            else
                echo "  [OK] $file"
            fi
        done

        echo ""
        echo "================================"
    } > "$report_file"

    log_info "报告已生成: $report_file"
}

# 主函数
main() {
    local do_report=false
    local ci_mode=false

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --report)
                do_report=true
                shift
                ;;
            --ci)
                ci_mode=true
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

    local exit_code=0

    # 扫描密钥
    if ! scan_all; then
        exit_code=1
    fi

    echo ""

    # 检查 .env 文件
    if ! check_env_files; then
        exit_code=1
    fi

    echo ""

    # 检查 .gitignore
    if ! check_gitignore; then
        exit_code=1
    fi

    # 生成报告
    if [[ "$do_report" == true ]]; then
        echo ""
        generate_report
    fi

    echo ""

    if [[ $exit_code -eq 0 ]]; then
        log_info "扫描完成：未发现安全问题"
    else
        log_error "扫描完成：发现安全问题"

        if [[ "$ci_mode" == true ]]; then
            log_error "CI 模式：构建失败"
            exit 1
        fi
    fi

    exit $exit_code
}

main "$@"
