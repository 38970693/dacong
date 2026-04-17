@echo off

echo 🔍 DaCong Flutter 环境检查
echo ================================
echo.

REM 检查 Flutter
echo 📱 Flutter 版本：
flutter --version | findstr /C:"Flutter"
echo.

REM 检查依赖
echo 📦 检查依赖安装状态：
if exist ".dart_tool" (
    echo ✅ 依赖已安装
) else (
    echo ❌ 依赖未安装，请运行: flutter pub get
)
echo.

REM 检查 .env 文件
echo ⚙️  检查环境配置：
if exist ".env" (
    echo ✅ .env 文件存在
    findstr /C:"YOUR_SUPABASE" .env >nul
    if %errorlevel% equ 0 (
        echo ⚠️  警告: .env 文件包含占位符，请填入真实配置
    ) else (
        echo ✅ .env 配置看起来正常
    )
) else (
    echo ❌ .env 文件不存在，请从 .env.example 复制
)
echo.

REM 检查生成文件
echo 🔨 检查代码生成状态：
dir /s /b lib\*.g.dart lib\*.freezed.dart 2>nul | find /c /v "" >nul
if %errorlevel% equ 0 (
    echo ✅ 找到生成文件
) else (
    echo ⚠️  未找到生成文件，可能需要运行: flutter pub run build_runner build
)
echo.

REM 检查设备
echo 📱 可用设备：
flutter devices
echo.

echo ================================
echo ✅ 环境检查完成！
echo.

pause
