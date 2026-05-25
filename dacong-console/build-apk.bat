@echo off
chcp 65001 >nul 2>&1

echo ========================================
echo    DaCong Android Build Script
echo ========================================
echo.

cd /d "%~dp0"

:: Set Java environment
set "JAVA_HOME=C:\Program Files\Java\jdk-17"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo [1/4] Cleaning old build...
if exist "out" (
    if exist "out\BUILD_ID" (
        :: out is a real directory - remove it
        rmdir /s /q "out"
    ) else (
        :: out is a symlink to .next - just recreate it
        del "out" 2>nul
    )
)
mklink /d "out" ".next" >nul 2>&1
if exist "android\app\build" rmdir /s /q "android\app\build"
echo       Done
echo.

echo [2/4] Building Next.js project...
call npm run build
if errorlevel 1 (
    echo.
    echo [ERROR] Next.js build failed!
    pause
    exit /b 1
)
echo       Done
echo.

echo [3/4] Syncing to Android...
cd /d "%~dp0"
echo       Current directory: %CD%
if exist "out" (
    echo       Found out folder - syncing...
) else (
    :: Recreate symlink if missing
    mklink /d "out" ".next" >nul 2>&1
    echo       Recreated out symlink - syncing...
)
call npx cap sync android
if errorlevel 1 (
    echo.
    echo [ERROR] Capacitor sync failed!
    pause
    exit /b 1
)
echo       Done
echo.

echo [4/4] Building APK...
cd android
set "JAVA_HOME=C:\Program Files\Java\jdk-17"
set "PATH=%JAVA_HOME%\bin;%PATH%"
call gradlew.bat assembleDebug --no-daemon
if errorlevel 1 (
    echo.
    echo [ERROR] APK build failed!
    pause
    exit /b 1
)
cd ..
echo       Done
echo.

echo ========================================
echo    Build Complete!
echo ========================================
echo.
echo APK location:
dir /s /b "android\app\build\outputs\*.apk" 2>nul
echo.
echo Press any key to open output folder...
pause >nul
explorer "android\app\build\outputs"