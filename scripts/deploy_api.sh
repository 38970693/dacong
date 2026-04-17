#!/bin/bash

# ============================================
# API 部署脚本 (Edge Functions)
# ============================================
# 用途：部署所有 Supabase Edge Functions
# 使用：./scripts/deploy_api.sh

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
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 获取项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT/dacong-api"

# 检查 Supabase CLI
if ! command -v supabase &> /dev/null; then
    log_error "Supabase CLI 未安装"
    exit 1
fi

# 加载环境变量
if [ -f "../.env.test.local" ]; then
    set -a
    source ../.env.test.local
    set +a
fi

log_info "开始部署 Edge Functions..."

# ============================================
# 1. 检查 Functions 目录
# ============================================
FUNCTIONS_DIR="supabase/functions"

if [ ! -d "$FUNCTIONS_DIR" ]; then
    log_error "Functions 目录不存在: $FUNCTIONS_DIR"
    exit 1
fi

cd "$FUNCTIONS_DIR"

# ============================================
# 2. 获取所有 Function 列表
# ============================================
log_info "扫描 Edge Functions..."

# 获取所有包含 index.ts 的目录
FUNCTIONS=($(find . -maxdepth 2 -name "index.ts" -exec dirname {} \; | sed 's|^\./||' | sort))

if [ ${#FUNCTIONS[@]} -eq 0 ]; then
    log_error "未找到任何 Edge Function"
    exit 1
fi

log_info "发现 ${#FUNCTIONS[@]} 个 Functions:"
for func in "${FUNCTIONS[@]}"; do
    echo "  - $func"
done

# ============================================
# 3. 部署每个 Function
# ============================================
DEPLOYED=0
FAILED=0
SKIPPED=0

echo ""
log_info "开始部署..."

for func in "${FUNCTIONS[@]}"; do
    # 跳过共享目录和特殊目录
    if [[ "$func" == "_shared" ]] || [[ "$func" == ".*" ]]; then
        log_warning "跳过: $func"
        ((SKIPPED++))
        continue
    fi

    log_info "部署 Function: $func"

    # 检查是否有 index.ts
    if [ ! -f "$func/index.ts" ]; then
        log_warning "跳过 $func: 缺少 index.ts"
        ((SKIPPED++))
        continue
    fi

    # 部署 Function
    if supabase functions deploy "$func" --no-verify-jwt 2>&1 | tee /tmp/deploy_$func.log; then
        log_success "✓ $func 部署成功"
        ((DEPLOYED++))
    else
        log_error "✗ $func 部署失败"
        cat /tmp/deploy_$func.log
        ((FAILED++))
    fi

    echo ""
done

# ============================================
# 4. 设置环境变量（如果需要）
# ============================================
if [ -n "$ANTHROPIC_API_KEY" ]; then
    log_info "设置 Edge Functions 环境变量..."

    # 为需要 API Key 的 Functions 设置环境变量
    FUNCTIONS_WITH_SECRETS=(
        "get-recommendations"
        "search-content"
        "get-weekly-report"
    )

    for func in "${FUNCTIONS_WITH_SECRETS[@]}"; do
        if [[ " ${FUNCTIONS[@]} " =~ " ${func} " ]]; then
            log_info "设置 $func 的环境变量"
            supabase secrets set ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" --env-file ../.env.test.local 2>/dev/null || true
        fi
    done
fi

# ============================================
# 5. 验证部署
# ============================================
log_info "验证部署..."

# 列出所有已部署的 Functions
DEPLOYED_FUNCTIONS=$(supabase functions list 2>/dev/null || echo "")

if [ -n "$DEPLOYED_FUNCTIONS" ]; then
    log_success "已部署的 Functions:"
    echo "$DEPLOYED_FUNCTIONS"
else
    log_warning "无法获取已部署的 Functions 列表"
fi

# ============================================
# 6. 部署总结
# ============================================
echo ""
log_info "=========================================="
log_info "部署总结"
log_info "=========================================="
log_success "成功: $DEPLOYED"
log_error "失败: $FAILED"
log_warning "跳过: $SKIPPED"
log_info "总计: ${#FUNCTIONS[@]}"
echo ""

if [ $FAILED -gt 0 ]; then
    log_error "部分 Functions 部署失败，请检查日志"
    exit 1
fi

log_success "所有 Edge Functions 部署完成"

# 输出访问信息
echo ""
log_info "API 访问信息:"
log_info "  基础 URL: $SUPABASE_URL/functions/v1/"
log_info "  认证: 使用 Authorization: Bearer <anon-key>"
echo ""
log_info "测试示例:"
echo "  curl '$SUPABASE_URL/functions/v1/get-recommendations' \\"
echo "    -H 'Authorization: Bearer $SUPABASE_ANON_KEY' \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"user_id\":\"test-user\",\"scenario\":\"morning\"}'"
echo ""
