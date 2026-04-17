@echo off

echo 🧪 运行 DaCong 测试...
echo.

REM 检查依赖
if not exist ".dart_tool" (
    echo ⚠️  依赖未安装，运行 flutter pub get...
    flutter pub get
    echo.
)

REM 运行测试
flutter test --coverage

echo.
echo ✅ 测试完成！
echo.
echo 📊 查看覆盖率报告：
echo    coverage\lcov.info
echo.

pause
