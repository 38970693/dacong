@echo off
setlocal enabledelayedexpansion

echo 🚀 DaCong Flutter 开发环境配置
echo ================================
echo.

REM 检查 Flutter 是否安装
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ Flutter 未安装，请先安装 Flutter SDK
    echo    访问: https://flutter.dev/docs/get-started/install
    exit /b 1
)

echo ✅ Flutter 已安装
flutter --version
echo.

REM 运行 Flutter Doctor
echo 🔍 检查 Flutter 环境...
flutter doctor
echo.

REM 检查 .env 文件
if not exist ".env" (
    echo ⚠️  .env 文件不存在，从 .env.example 复制...
    copy .env.example .env
    echo ✅ 已创建 .env 文件，请编辑并填入正确的配置
    echo.
)

REM 安装依赖
echo 📦 安装依赖...
flutter pub get
echo.

REM 运行代码生成
echo 🔨 运行代码生成...
flutter pub run build_runner build --delete-conflicting-outputs
echo.

REM 验证配置
echo ✅ 配置完成！
echo.
echo 📝 下一步：
echo    1. 编辑 .env 文件，填入正确的 Supabase 配置
echo    2. 运行 scripts\run-web.bat 启动 Web 版本
echo    3. 运行 scripts\run-android.bat 启动 Android 版本
echo    4. 运行 scripts\test.bat 运行测试
echo.

pause
