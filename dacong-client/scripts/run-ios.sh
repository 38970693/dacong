#!/bin/bash

set -e

echo "🍎 启动 DaCong iOS 版本..."
echo ""

# 检查操作系统
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ iOS 开发仅支持 macOS"
    exit 1
fi

# 检查依赖
if [ ! -d ".dart_tool" ]; then
    echo "⚠️  依赖未安装，运行 flutter pub get..."
    flutter pub get
    echo ""
fi

# 检查 iOS 设备
echo "🔍 检查 iOS 设备..."
flutter devices | grep ios
if [ $? -ne 0 ]; then
    echo "❌ 未检测到 iOS 设备或模拟器"
    echo "   请连接 iOS 设备或启动模拟器"
    exit 1
fi

echo ""

# 启动 iOS 版本
flutter run -d ios
