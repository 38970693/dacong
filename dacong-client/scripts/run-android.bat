@echo off

echo 📱 启动 DaCong Android 版本...
echo.

REM 检查依赖
if not exist ".dart_tool" (
    echo ⚠️  依赖未安装，运行 flutter pub get...
    flutter pub get
    echo.
)

REM 检查 Android 设备
echo 🔍 检查 Android 设备...
flutter devices | findstr /C:"android" >nul
if %errorlevel% neq 0 (
    echo ❌ 未检测到 Android 设备或模拟器
    echo    请连接 Android 设备或启动模拟器
    pause
    exit /b 1
)

echo.

REM 启动 Android 版本
flutter run -d android
