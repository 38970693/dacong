#!/bin/bash

# ============================================
# 前端冒烟测试
# ============================================
# 用途：验证前端构建和关键页面
# 使用：./tests/smoke/test_frontend_smoke.sh

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

# 获取项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

BUILD_DIR="$PROJECT_ROOT/dacong-client/build/web"

log_info "开始前端冒烟测试..."

# 测试计数器
PASSED=0
FAILED=0

# 测试函数
test_file() {
    local name="$1"
    local file="$2"

    log_info "测试: $name"

    if [ -f "$file" ]; then
        log_success "✓ $name"
        ((PASSED++))
        return 0
    else
        log_error "✗ $name (文件不存在: $file)"
        ((FAILED++))
        return 1
    fi
}

test_content() {
    local name="$1"
    local file="$2"
    local pattern="$3"

    log_info "测试: $name"

    if grep -q "$pattern" "$file"; then
        log_success "✓ $name"
        ((PASSED++))
        return 0
    else
        log_error "✗ $name (未找到: $pattern)"
        ((FAILED++))
        return 1
    fi
}

# ============================================
# 1. 构建文件检查
# ============================================
log_info "检查构建文件..."

test_file "构建目录存在" "$BUILD_DIR"
test_file "index.html 存在" "$BUILD_DIR/index.html"
test_file "main.dart.js 存在" "$BUILD_DIR/main.dart.js"
test_file "flutter.js 存在" "$BUILD_DIR/flutter.js"
test_file "manifest.json 存在" "$BUILD_DIR/manifest.json"
test_file "favicon.png 存在" "$BUILD_DIR/favicon.png"

# ============================================
# 2. HTML 内容检查
# ============================================
log_info "检查 HTML 内容..."

test_content "HTML 包含 Flutter 初始化" \
    "$BUILD_DIR/index.html" \
    "flutter.js"

test_content "HTML 包含 viewport meta" \
    "$BUILD_DIR/index.html" \
    "viewport"

test_content "HTML 包含 title" \
    "$BUILD_DIR/index.html" \
    "<title>"

# ============================================
# 3. 资源文件检查
# ============================================
log_info "检查资源文件..."

# 检查 assets 目录
if [ -d "$BUILD_DIR/assets" ]; then
    log_success "✓ assets 目录存在"
    ((PASSED++))

    # 检查字体文件
    if find "$BUILD_DIR/assets" -name "*.ttf" -o -name "*.otf" | grep -q .; then
        log_success "✓ 字体文件存在"
        ((PASSED++))
    else
        log_error "✗ 未找到字体文件"
        ((FAILED++))
    fi
else
    log_error "✗ assets 目录不存在"
    ((FAILED++))
fi

# ============================================
# 4. 文件大小检查
# ============================================
log_info "检查文件大小..."

# 检查 main.dart.js 大小（不应该太大）
MAIN_JS_SIZE=$(stat -f%z "$BUILD_DIR/main.dart.js" 2>/dev/null || stat -c%s "$BUILD_DIR/main.dart.js" 2>/dev/null || echo 0)

if [ "$MAIN_JS_SIZE" -gt 0 ] && [ "$MAIN_JS_SIZE" -lt 10485760 ]; then  # < 10MB
    log_success "✓ main.dart.js 大小合理 ($(numfmt --to=iec-i --suffix=B $MAIN_JS_SIZE 2>/dev/null || echo "$MAIN_JS_SIZE bytes"))"
    ((PASSED++))
else
    log_error "✗ main.dart.js 大小异常"
    ((FAILED++))
fi

# ============================================
# 5. 启动本地服务器测试（可选）
# ============================================
if [ "$START_SERVER" = "true" ]; then
    log_info "启动本地服务器测试..."

    # 启动服务器
    cd "$BUILD_DIR"
    python3 -m http.server 8080 &
    SERVER_PID=$!

    # 等待服务器启动
    sleep 2

    # 测试首页加载
    if curl -s -f http://localhost:8080/ > /dev/null; then
        log_success "✓ 首页加载成功"
        ((PASSED++))
    else
        log_error "✗ 首页加载失败"
        ((FAILED++))
    fi

    # 关闭服务器
    kill $SERVER_PID 2>/dev/null || true
fi

# ============================================
# 测试总结
# ============================================
echo ""
log_info "=========================================="
log_info "前端冒烟测试完成"
log_info "=========================================="
log_success "通过: $PASSED"
log_error "失败: $FAILED"
log_info "总计: $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    log_success "所有前端测试通过！"
    exit 0
else
    log_error "部分前端测试失败"
    exit 1
fi
