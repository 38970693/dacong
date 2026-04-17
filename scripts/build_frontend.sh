#!/bin/bash

# ============================================
# 前端构建脚本
# ============================================
# 用途：构建 Flutter Web 应用
# 使用：./scripts/build_frontend.sh

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

cd "$PROJECT_ROOT/dacong-client"

# 检查 Flutter
if ! command -v flutter &> /dev/null; then
    log_error "Flutter 未安装"
    exit 1
fi

log_info "开始构建前端..."

# ============================================
# 1. 环境检查
# ============================================
log_info "检查 Flutter 环境..."

flutter doctor -v

# 检查 Flutter 版本
FLUTTER_VERSION=$(flutter --version | head -n 1)
log_info "Flutter 版本: $FLUTTER_VERSION"

# ============================================
# 2. 清理旧构建
# ============================================
log_info "清理旧构建..."

flutter clean

log_success "清理完成"

# ============================================
# 3. 获取依赖
# ============================================
log_info "获取依赖..."

flutter pub get

# 检查依赖是否有问题
if flutter pub outdated | grep -q "outdated"; then
    log_warning "存在过期的依赖包，建议运行: flutter pub upgrade"
fi

log_success "依赖获取完成"

# ============================================
# 4. 代码生成（如果需要）
# ============================================
if [ -f "build.yaml" ] || grep -q "build_runner" pubspec.yaml; then
    log_info "运行代码生成..."
    flutter pub run build_runner build --delete-conflicting-outputs
    log_success "代码生成完成"
fi

# ============================================
# 5. 构建 Web
# ============================================
log_info "构建 Flutter Web (Release 模式)..."

# 构建参数
BUILD_ARGS=(
    "--release"
    "--web-renderer=canvaskit"  # 使用 CanvasKit 渲染器以获得更好的性能
    "--dart-define=FLUTTER_WEB_USE_SKIA=true"
)

# 如果有环境变量，传递给构建
if [ -f ".env" ]; then
    log_info "加载环境变量..."
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        [[ $key =~ ^#.*$ ]] && continue
        [[ -z $key ]] && continue

        # 移除值两端的引号
        value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")

        BUILD_ARGS+=("--dart-define=$key=$value")
    done < .env
fi

# 执行构建
if flutter build web "${BUILD_ARGS[@]}"; then
    log_success "构建成功"
else
    log_error "构建失败"
    exit 1
fi

# ============================================
# 6. 构建信息
# ============================================
BUILD_DIR="build/web"

log_info "构建输出目录: $BUILD_DIR"

if [ -d "$BUILD_DIR" ]; then
    # 计算构建大小
    BUILD_SIZE=$(du -sh "$BUILD_DIR" | cut -f1)
    log_info "构建大小: $BUILD_SIZE"

    # 列出主要文件
    log_info "主要文件:"
    ls -lh "$BUILD_DIR" | grep -E '\.(html|js|wasm)$' || true

    # 检查关键文件
    CRITICAL_FILES=(
        "index.html"
        "main.dart.js"
        "flutter.js"
    )

    for file in "${CRITICAL_FILES[@]}"; do
        if [ -f "$BUILD_DIR/$file" ]; then
            SIZE=$(du -h "$BUILD_DIR/$file" | cut -f1)
            log_success "✓ $file ($SIZE)"
        else
            log_error "✗ $file 缺失"
            exit 1
        fi
    done
else
    log_error "构建目录不存在: $BUILD_DIR"
    exit 1
fi

# ============================================
# 7. 生成构建清单
# ============================================
MANIFEST_FILE="$BUILD_DIR/build_manifest.json"

cat > "$MANIFEST_FILE" << EOF
{
  "build_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "flutter_version": "$FLUTTER_VERSION",
  "build_mode": "release",
  "web_renderer": "canvaskit",
  "build_size": "$BUILD_SIZE",
  "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
  "git_branch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
}
EOF

log_success "构建清单已生成: $MANIFEST_FILE"

# ============================================
# 8. 优化建议
# ============================================
echo ""
log_info "=========================================="
log_info "构建完成"
log_info "=========================================="
log_success "输出目录: $BUILD_DIR"
log_success "构建大小: $BUILD_SIZE"
echo ""

log_info "部署建议:"
echo "  1. 本地测试: flutter run -d chrome --release"
echo "  2. 启动服务器: python -m http.server 8080 -d $BUILD_DIR"
echo "  3. 部署到 CDN: 上传 $BUILD_DIR 目录到静态托管服务"
echo ""

log_info "性能优化:"
echo "  - 启用 gzip 压缩"
echo "  - 配置 CDN 缓存"
echo "  - 使用 HTTP/2"
echo "  - 添加 Service Worker 支持离线访问"
echo ""

# ============================================
# 9. 可选：启动本地预览服务器
# ============================================
if [ "$START_SERVER" = "true" ]; then
    log_info "启动本地预览服务器..."

    if command -v python3 &> /dev/null; then
        cd "$BUILD_DIR"
        log_success "服务器运行在: http://localhost:8080"
        python3 -m http.server 8080
    elif command -v python &> /dev/null; then
        cd "$BUILD_DIR"
        log_success "服务器运行在: http://localhost:8080"
        python -m http.server 8080
    else
        log_warning "Python 未安装，无法启动预览服务器"
        log_info "请手动启动服务器或使用其他工具"
    fi
fi
