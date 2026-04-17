@echo off

echo 🌐 启动 DaCong Web 版本...
echo.

REM 检查依赖
if not exist ".dart_tool" (
    echo ⚠️  依赖未安装，运行 flutter pub get...
    flutter pub get
    echo.
)

REM 启动 Web 版本
flutter run -d chrome --web-port 3000
