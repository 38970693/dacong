#!/bin/bash

# 打包体积分析脚本
# 用于分析 Flutter 应用的打包体积和性能

set -e

echo "=========================================="
echo "DaCong Client - 打包体积分析"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否在项目根目录
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}错误: 请在项目根目录运行此脚本${NC}"
    exit 1
fi

# 创建输出目录
OUTPUT_DIR="build/analysis"
mkdir -p "$OUTPUT_DIR"

echo "1. 清理旧的构建文件..."
flutter clean
echo -e "${GREEN}✓ 清理完成${NC}"
echo ""

echo "2. 获取依赖..."
flutter pub get
echo -e "${GREEN}✓ 依赖获取完成${NC}"
echo ""

echo "3. 构建 APK (Android)..."
flutter build apk --release --analyze-size --target-platform android-arm64
APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
echo -e "${GREEN}✓ APK 构建完成 - 大小: $APK_SIZE${NC}"
echo ""

echo "4. 构建 App Bundle (Android)..."
flutter build appbundle --release --analyze-size
AAB_SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
echo -e "${GREEN}✓ App Bundle 构建完成 - 大小: $AAB_SIZE${NC}"
echo ""

echo "5. 分析代码大小..."
flutter build apk --release --analyze-size --target-platform android-arm64 > "$OUTPUT_DIR/size_analysis.txt" 2>&1
echo -e "${GREEN}✓ 代码大小分析完成${NC}"
echo ""

echo "6. 生成依赖树..."
flutter pub deps --style=compact > "$OUTPUT_DIR/dependencies.txt"
echo -e "${GREEN}✓ 依赖树生成完成${NC}"
echo ""

echo "7. 分析未使用的文件..."
dart run dart_code_metrics:metrics analyze lib --reporter=html --output-directory="$OUTPUT_DIR/metrics"
echo -e "${GREEN}✓ 代码度量分析完成${NC}"
echo ""

# 生成摘要报告
REPORT_FILE="$OUTPUT_DIR/summary_report.txt"
echo "========================================" > "$REPORT_FILE"
echo "打包体积分析报告" >> "$REPORT_FILE"
echo "生成时间: $(date)" >> "$REPORT_FILE"
echo "========================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "构建产物大小:" >> "$REPORT_FILE"
echo "  - APK:         $APK_SIZE" >> "$REPORT_FILE"
echo "  - App Bundle:  $AAB_SIZE" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 统计代码行数
echo "代码统计:" >> "$REPORT_FILE"
DART_FILES=$(find lib -name "*.dart" | wc -l)
DART_LINES=$(find lib -name "*.dart" -exec cat {} \; | wc -l)
echo "  - Dart 文件数: $DART_FILES" >> "$REPORT_FILE"
echo "  - 代码总行数:  $DART_LINES" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 依赖统计
echo "依赖统计:" >> "$REPORT_FILE"
DIRECT_DEPS=$(grep -c "^  [a-z]" pubspec.yaml || true)
echo "  - 直接依赖数: $DIRECT_DEPS" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "详细报告已保存到:" >> "$REPORT_FILE"
echo "  - 大小分析:   $OUTPUT_DIR/size_analysis.txt" >> "$REPORT_FILE"
echo "  - 依赖树:     $OUTPUT_DIR/dependencies.txt" >> "$REPORT_FILE"
echo "  - 代码度量:   $OUTPUT_DIR/metrics/index.html" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 性能建议
echo "性能优化建议:" >> "$REPORT_FILE"
echo "  1. 检查未使用的依赖并移除" >> "$REPORT_FILE"
echo "  2. 使用代码分割减少初始加载大小" >> "$REPORT_FILE"
echo "  3. 优化图片资源（使用 WebP 格式）" >> "$REPORT_FILE"
echo "  4. 启用混淆和压缩" >> "$REPORT_FILE"
echo "  5. 移除调试代码和日志" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 显示摘要
cat "$REPORT_FILE"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}分析完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "完整报告位置: $OUTPUT_DIR/summary_report.txt"
echo ""

# 检查是否超过大小限制
APK_SIZE_MB=$(du -m build/app/outputs/flutter-apk/app-release.apk | cut -f1)
if [ "$APK_SIZE_MB" -gt 50 ]; then
    echo -e "${YELLOW}警告: APK 大小超过 50MB，建议优化${NC}"
fi

# 打开 HTML 报告（可选）
if command -v xdg-open &> /dev/null; then
    echo "是否打开 HTML 报告？(y/n)"
    read -r response
    if [ "$response" = "y" ]; then
        xdg-open "$OUTPUT_DIR/metrics/index.html"
    fi
fi
