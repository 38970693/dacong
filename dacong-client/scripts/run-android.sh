#!/bin/bash

set -e

echo "📱 启动 DaCong Android 版本..."
echo ""

# 检查依赖
if [ ! -d ".dart_tool" ]; then
    echo "⚠️  依赖未安装，运行 flutter pub get..."
    flutter pub get
    echo ""
fi

# 检查 Android 设备
echo "🔍 检查 Android 设备..."
flutter devices | grep android
if [ $? -ne 0 ]; then
    echo "❌ 未检测到 Android 设备或模拟器"
    echo "   请连接 Android 设备或启动模拟器"
    exit 1
fi

echo ""

# 启动 Android 版本
flutter run -d android
