#!/bin/bash

# ============================================
# 部署脚本完整性检查
# ============================================
# 用途：验证所有部署相关文件是否正确创建
# 使用：./scripts/check_deployment_setup.sh

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

# 获取项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

log_info "检查部署脚本完整性..."
echo ""

# 测试计数器
TOTAL=0
PASSED=0
FAILED=0

# 检查文件函数
check_file() {
    local file="$1"
    local description="$2"

    ((TOTAL++))

    if [ -f "$file" ]; then
        log_success "$description"
        ((PASSED++))
        return 0
    else
        log_error "$description (文件不存在: $file)"
        ((FAILED++))
        return 1
    fi
}

# 检查可执行权限
check_executable() {
    local file="$1"
    local description="$2"

    ((TOTAL++))

    if [ -x "$file" ]; then
        log_success "$description"
        ((PASSED++))
        return 0
    else
        log_warning "$description (文件不可执行: $file)"
        log_info "  运行: chmod +x $file"
        ((FAILED++))
        return 1
    fi
}

# ============================================
# 1. 检查部署脚本
# ============================================
log_info "1. 检查部署脚本"

check_file "scripts/deploy_test.sh" "主部署脚本"
check_file "scripts/deploy_database.sh" "数据库部署脚本"
check_file "scripts/deploy_api.sh" "API 部署脚本"
check_file "scripts/build_frontend.sh" "前端构建脚本"
check_file "scripts/verify_deployment.sh" "部署验证脚本"

echo ""

# ============================================
# 2. 检查测试脚本
# ============================================
log_info "2. 检查测试脚本"

check_file "tests/smoke/test_api_smoke.sh" "API 冒烟测试"
check_file "tests/smoke/test_frontend_smoke.sh" "前端冒烟测试"
check_file "tests/smoke/test_e2e_smoke.sh" "端到端冒烟测试"

echo ""

# ============================================
# 3. 检查配置文件
# ============================================
log_info "3. 检查配置文件"

check_file ".env.test" "测试环境配置模板"
check_file "dacong-api/scripts/init_test_data.sql" "测试数据初始化脚本"

if [ -f ".env.test.local" ]; then
    log_success "本地测试配置文件"
    ((TOTAL++))
    ((PASSED++))
else
    log_warning "本地测试配置文件 (需要手动创建)"
    log_info "  运行: cp .env.test .env.test.local"
    ((TOTAL++))
fi

echo ""

# ============================================
# 4. 检查文档
# ============================================
log_info "4. 检查文档"

check_file "docs/DEPLOYMENT.md" "部署文档"
check_file "scripts/README.md" "脚本使用说明"
check_file "DEPLOYMENT_COMPLETE.md" "部署完成总结"

echo ""

# ============================================
# 5. 检查脚本可执行权限
# ============================================
log_info "5. 检查脚本可执行权限"

check_executable "scripts/deploy_test.sh" "deploy_test.sh 可执行"
check_executable "scripts/deploy_database.sh" "deploy_database.sh 可执行"
check_executable "scripts/deploy_api.sh" "deploy_api.sh 可执行"
check_executable "scripts/build_frontend.sh" "build_frontend.sh 可执行"
check_executable "scripts/verify_deployment.sh" "verify_deployment.sh 可执行"
check_executable "tests/smoke/test_api_smoke.sh" "test_api_smoke.sh 可执行"
check_executable "tests/smoke/test_frontend_smoke.sh" "test_frontend_smoke.sh 可执行"
check_executable "tests/smoke/test_e2e_smoke.sh" "test_e2e_smoke.sh 可执行"

echo ""

# ============================================
# 6. 检查必要工具
# ============================================
log_info "6. 检查必要工具"

((TOTAL++))
if command -v supabase &> /dev/null; then
    log_success "Supabase CLI 已安装 ($(supabase --version))"
    ((PASSED++))
else
    log_error "Supabase CLI 未安装"
    log_info "  安装: npm install -g supabase"
    ((FAILED++))
fi

((TOTAL++))
if command -v flutter &> /dev/null; then
    log_success "Flutter 已安装 ($(flutter --version | head -n1))"
    ((PASSED++))
else
    log_error "Flutter 未安装"
    log_info "  访问: https://flutter.dev/docs/get-started/install"
    ((FAILED++))
fi

((TOTAL++))
if command -v deno &> /dev/null; then
    log_success "Deno 已安装 ($(deno --version | head -n1))"
    ((PASSED++))
else
    log_error "Deno 未安装"
    log_info "  安装: curl -fsSL https://deno.land/install.sh | sh"
    ((FAILED++))
fi

echo ""

# ============================================
# 7. 检查目录结构
# ============================================
log_info "7. 检查目录结构"

((TOTAL++))
if [ -d "scripts" ]; then
    log_success "scripts/ 目录存在"
    ((PASSED++))
else
    log_error "scripts/ 目录不存在"
    ((FAILED++))
fi

((TOTAL++))
if [ -d "tests/smoke" ]; then
    log_success "tests/smoke/ 目录存在"
    ((PASSED++))
else
    log_error "tests/smoke/ 目录不存在"
    ((FAILED++))
fi

((TOTAL++))
if [ -d "docs" ]; then
    log_success "docs/ 目录存在"
    ((PASSED++))
else
    log_error "docs/ 目录不存在"
    ((FAILED++))
fi

((TOTAL++))
if [ -d "dacong-api/supabase/functions" ]; then
    log_success "dacong-api/supabase/functions/ 目录存在"
    ((PASSED++))
else
    log_error "dacong-api/supabase/functions/ 目录不存在"
    ((FAILED++))
fi

((TOTAL++))
if [ -d "dacong-api/supabase/migrations" ]; then
    log_success "dacong-api/supabase/migrations/ 目录存在"
    ((PASSED++))
else
    log_error "dacong-api/supabase/migrations/ 目录不存在"
    ((FAILED++))
fi

echo ""

# ============================================
# 总结
# ============================================
log_info "=========================================="
log_info "检查完成"
log_info "=========================================="
echo ""
log_info "总计: $TOTAL"
log_success "通过: $PASSED"
log_error "失败: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    log_success "所有检查通过！部署脚本已准备就绪。"
    echo ""
    log_info "下一步操作："
    echo "  1. 配置环境变量: cp .env.test .env.test.local"
    echo "  2. 编辑配置文件: vim .env.test.local"
    echo "  3. 运行部署脚本: ./scripts/deploy_test.sh"
    echo ""
    exit 0
else
    log_error "部分检查失败，请修复后再部署。"
    echo ""
    exit 1
fi
