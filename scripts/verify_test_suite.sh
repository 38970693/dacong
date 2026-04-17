#!/bin/bash

# 验证测试套件安装
# 检查所有测试文件是否正确创建并可执行

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo ""
echo "=========================================="
echo "  测试套件验证"
echo "=========================================="
echo ""

TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

check_file() {
    local file=$1
    local should_be_executable=$2

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [ -f "$file" ]; then
        if [ "$should_be_executable" = "true" ]; then
            if [ -x "$file" ]; then
                log_success "$file (可执行)"
                PASSED_CHECKS=$((PASSED_CHECKS + 1))
            else
                log_warning "$file (存在但不可执行)"
                log_info "  修复: chmod +x $file"
                PASSED_CHECKS=$((PASSED_CHECKS + 1))
            fi
        else
            log_success "$file"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        fi
    else
        log_error "$file (不存在)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

# 检查测试脚本
log_info "检查测试脚本..."
check_file "tests/integration/test_end_to_end.sh" true
check_file "tests/performance/test_api_performance.sh" true
check_file "scripts/health_check.sh" true
check_file "scripts/run_all_tests.sh" true

echo ""

# 检查文档
log_info "检查文档..."
check_file "docs/TESTING.md" false
check_file "tests/integration/README.md" false
check_file "tests/performance/README.md" false
check_file "TESTING_QUICKSTART.md" false
check_file "INTEGRATION_TEST_COMPLETE.md" false

echo ""

# 检查目录结构
log_info "检查目录结构..."
for dir in "tests/integration" "tests/performance" "scripts" "docs"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ -d "$dir" ]; then
        log_success "目录 $dir"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        log_error "目录 $dir (不存在)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
done

echo ""

# 检查环境
log_info "检查环境依赖..."

# Python
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    log_success "Python: $PYTHON_VERSION"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    log_warning "Python 未安装"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Deno
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if command -v deno &> /dev/null; then
    DENO_VERSION=$(deno --version | head -n 1)
    log_success "Deno: $DENO_VERSION"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    log_warning "Deno 未安装"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

# Flutter
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    log_success "Flutter: $FLUTTER_VERSION"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    log_warning "Flutter 未安装"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi

echo ""

# 检查配置文件
log_info "检查配置文件..."

for config in "dacong-api/.env" "dacong-spider/.env" "dacong-client/.env"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ -f "$config" ]; then
        log_success "$config"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        log_warning "$config (不存在，测试可能失败)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
done

echo ""

# 生成摘要
echo "=========================================="
echo "  验证摘要"
echo "=========================================="
echo ""
echo "总检查项: $TOTAL_CHECKS"
echo "通过: $PASSED_CHECKS"
echo "失败: $FAILED_CHECKS"
echo ""

if [ $FAILED_CHECKS -eq 0 ]; then
    log_success "所有检查通过！测试套件已正确安装。"
    echo ""
    echo "下一步："
    echo "  1. 运行健康检查: ./scripts/health_check.sh"
    echo "  2. 运行所有测试: ./scripts/run_all_tests.sh"
    echo "  3. 查看文档: cat docs/TESTING.md"
    echo ""
    exit 0
else
    log_error "有 $FAILED_CHECKS 个检查失败。"
    echo ""
    echo "修复建议："
    echo "  1. 确保所有脚本有执行权限: chmod +x tests/**/*.sh scripts/*.sh"
    echo "  2. 创建配置文件: cp .env.example .env"
    echo "  3. 安装缺失的依赖"
    echo ""
    exit 1
fi
