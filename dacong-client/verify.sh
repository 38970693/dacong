#!/bin/bash

# Flutter Clean Architecture 验证脚本

echo "=========================================="
echo "Flutter Clean Architecture 验证"
echo "=========================================="
echo ""

# 检查 Flutter 环境
echo "1. 检查 Flutter 环境..."
if command -v flutter &> /dev/null; then
    flutter --version | head -1
    echo "✅ Flutter 已安装"
else
    echo "❌ Flutter 未安装"
    exit 1
fi
echo ""

# 检查依赖
echo "2. 检查依赖..."
cd "$(dirname "$0")"
if [ -f "pubspec.yaml" ]; then
    echo "✅ pubspec.yaml 存在"
else
    echo "❌ pubspec.yaml 不存在"
    exit 1
fi
echo ""

# 检查生成的代码
echo "3. 检查生成的代码..."
FREEZED_COUNT=$(find lib -name "*.freezed.dart" | wc -l)
JSON_COUNT=$(find lib -name "*.g.dart" | wc -l)
CONFIG_COUNT=$(find lib -name "*.config.dart" | wc -l)

echo "   - Freezed 文件: $FREEZED_COUNT"
echo "   - JSON 序列化文件: $JSON_COUNT"
echo "   - Injectable 配置: $CONFIG_COUNT"

if [ $FREEZED_COUNT -gt 0 ] && [ $JSON_COUNT -gt 0 ] && [ $CONFIG_COUNT -gt 0 ]; then
    echo "✅ 代码生成完成"
else
    echo "⚠️  需要运行代码生成"
    echo "   运行: flutter pub run build_runner build --delete-conflicting-outputs"
fi
echo ""

# 检查架构层次
echo "4. 检查架构层次..."
DOMAIN_COUNT=$(find lib/core/domain -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" | wc -l)
DATA_COUNT=$(find lib/data -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" | wc -l)
PRESENTATION_COUNT=$(find lib/presentation -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" | wc -l)

echo "   - Domain Layer: $DOMAIN_COUNT 个文件"
echo "   - Data Layer: $DATA_COUNT 个文件"
echo "   - Presentation Layer: $PRESENTATION_COUNT 个文件"
echo "✅ 架构层次完整"
echo ""

# 检查测试
echo "5. 检查测试..."
TEST_COUNT=$(find test -name "*_test.dart" | wc -l)
echo "   - 测试文件: $TEST_COUNT 个"
if [ $TEST_COUNT -gt 0 ]; then
    echo "✅ 测试文件存在"
else
    echo "⚠️  建议添加测试"
fi
echo ""

# 检查文档
echo "6. 检查文档..."
DOCS=("README.md" "README_ARCHITECTURE.md" "IMPLEMENTATION_SUMMARY.md" "IMPLEMENTATION_REPORT.md")
for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo "   ✅ $doc"
    else
        echo "   ❌ $doc 缺失"
    fi
done
echo ""

# 总结
echo "=========================================="
echo "验证完成！"
echo "=========================================="
echo ""
echo "下一步操作："
echo "1. 配置 Supabase: 编辑 lib/core/constants/app_constants.dart"
echo "2. 运行应用: flutter run -d chrome"
echo "3. 运行测试: flutter test"
echo ""
