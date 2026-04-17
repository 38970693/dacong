@echo off

echo 🔨 运行代码生成...
echo.

REM 检查依赖
if not exist ".dart_tool" (
    echo ⚠️  依赖未安装，运行 flutter pub get...
    flutter pub get
    echo.
)

REM 清理旧的生成文件
echo 🧹 清理旧的生成文件...
flutter pub run build_runner clean

echo.

REM 运行代码生成
echo ⚙️  生成代码...
flutter pub run build_runner build --delete-conflicting-outputs

echo.
echo ✅ 代码生成完成！
echo.

pause
