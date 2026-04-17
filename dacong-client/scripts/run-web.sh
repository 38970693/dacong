#!/bin/bash

set -e

echo "🌐 启动 DaCong Web 版本..."
echo ""

# 检查依赖
if [ ! -d ".dart_tool" ]; then
    echo "⚠️  依赖未安装，运行 flutter pub get..."
    flutter pub get
    echo ""
fi

# 启动 Web 版本
flutter run -d chrome --web-port 3000
