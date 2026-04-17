#!/bin/bash

echo "🔍 DaCong Flutter 环境检查"
echo "================================"
echo ""

# 检查 Flutter
echo "📱 Flutter 版本："
flutter --version | head -1
echo ""

# 检查依赖
echo "📦 检查依赖安装状态："
if [ -d ".dart_tool" ]; then
    echo "✅ 依赖已安装"
else
    echo "❌ 依赖未安装，请运行: flutter pub get"
fi
echo ""

# 检查 .env 文件
echo "⚙️  检查环境配置："
if [ -f ".env" ]; then
    echo "✅ .env 文件存在"
    if grep -q "YOUR_SUPABASE" .env; then
        echo "⚠️  警告: .env 文件包含占位符，请填入真实配置"
    else
        echo "✅ .env 配置看起来正常"
    fi
else
    echo "❌ .env 文件不存在，请从 .env.example 复制"
fi
echo ""

# 检查生成文件
echo "🔨 检查代码生成状态："
generated_files=$(find lib -name "*.g.dart" -o -name "*.freezed.dart" 2>/dev/null | wc -l)
if [ "$generated_files" -gt 0 ]; then
    echo "✅ 找到 $generated_files 个生成文件"
else
    echo "⚠️  未找到生成文件，可能需要运行: flutter pub run build_runner build"
fi
echo ""

# 检查设备
echo "📱 可用设备："
flutter devices
echo ""

echo "================================"
echo "✅ 环境检查完成！"
