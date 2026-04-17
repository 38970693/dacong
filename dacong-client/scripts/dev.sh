#!/bin/bash

# DaCong Client 开发脚本
# 用于启动开发服务器和热重载

set -e

echo "🚀 启动 DaCong Client 开发环境..."

# 检查 Flutter 是否安装
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter 未安装，请先安装 Flutter"
    exit 1
fi

# 检查依赖
echo "📦 检查依赖..."
flutter pub get

# 生成代码
echo "🔨 生成代码..."
dart run build_runner build --delete-conflicting-outputs

# 生成国际化文件
echo "🌍 生成国际化文件..."
flutter gen-l10n

# 启动开发服务器
echo "✨ 启动开发服务器（热重载已启用）..."
echo ""
echo "提示："
echo "  - 按 'r' 热重载"
echo "  - 按 'R' 热重启"
echo "  - 按 'h' 查看帮助"
echo "  - 按 'q' 退出"
echo ""

flutter run --hot
