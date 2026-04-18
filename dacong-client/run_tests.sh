#!/bin/bash

# 大葱项目测试运行脚本
# 用于运行 Flutter 客户端测试并生成覆盖率报告

set -e

echo "=========================================="
echo "大葱项目 - Flutter 客户端测试"
echo "=========================================="
echo ""

# 进入客户端目录
cd "$(dirname "$0")"

# 检查 Flutter 是否安装
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter 未安装，请先安装 Flutter"
    exit 1
fi

echo "✅ Flutter 版本:"
flutter --version | head -1
echo ""

# 获取依赖
echo "📦 获取依赖..."
flutter pub get
echo ""

# 运行代码生成（如果需要）
if [ "$1" == "--generate" ]; then
    echo "🔧 运行代码生成..."
    flutter pub run build_runner build --delete-conflicting-outputs
    echo ""
fi

# 运行测试
echo "🧪 运行测试..."
echo ""

if [ "$1" == "--coverage" ] || [ "$2" == "--coverage" ]; then
    # 运行测试并生成覆盖率
    flutter test --coverage

    echo ""
    echo "=========================================="
    echo "📊 测试覆盖率报告已生成"
    echo "=========================================="
    echo "覆盖率文件: coverage/lcov.info"
    echo ""

    # 如果安装了 lcov，生成 HTML 报告
    if command -v lcov &> /dev/null; then
        echo "生成 HTML 覆盖率报告..."
        genhtml coverage/lcov.info -o coverage/html --quiet
        echo "✅ HTML 报告已生成: coverage/html/index.html"
        echo ""

        # 尝试打开报告
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open coverage/html/index.html
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            xdg-open coverage/html/index.html 2>/dev/null || echo "请手动打开: coverage/html/index.html"
        fi
    else
        echo "💡 提示: 安装 lcov 可以生成 HTML 覆盖率报告"
        echo "   macOS: brew install lcov"
        echo "   Ubuntu: sudo apt-get install lcov"
    fi
else
    # 只运行测试
    flutter test
fi

echo ""
echo "=========================================="
echo "✅ 测试完成"
echo "=========================================="
