@echo off
chcp 65001 >nul
echo ========================================
echo   DaCong 一键启动脚本
echo ========================================
echo.

REM 检查必要的工具
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未找到 Flutter，请先安装 Flutter
    pause
    exit /b 1
)

where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未找到 Node.js，请先安装 Node.js
    pause
    exit /b 1
)

where python >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未找到 Python，请先安装 Python
    pause
    exit /b 1
)

echo [✓] 环境检查通过
echo.

REM 创建日志目录
if not exist "logs" mkdir logs

echo ========================================
echo   启动服务...
echo ========================================
echo.

REM 1. 启动前台客户端 (Flutter Web - 端口 8081)
echo [1/3] 启动前台客户端 (http://localhost:8081)...
start "DaCong Client" cmd /c "cd dacong-client && flutter run -d chrome --web-port=8081 --dart-define=DEV_MODE=true --dart-define=SUPABASE_URL=https://twrxnqrisplmetbceyqm.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR3cnhucXJpc3BsbWV0YmNleXFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNjAzNTcsImV4cCI6MjA5MTgzNjM1N30.GQm3JUk2jkHf_boqj_vTRusWqvhEN55lLG3tdPYnohw > ../logs/client.log 2>&1"
timeout /t 3 /nobreak >nul

REM 2. 启动后台管理 (Flutter Web - 端口 8080)
echo [2/3] 启动后台管理 (http://localhost:8080)...
start "DaCong Admin" cmd /c "cd dacong-admin && flutter run -d chrome --web-port=8080 --dart-define=DEV_MODE=true --dart-define=SUPABASE_URL=https://twrxnqrisplmetbceyqm.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR3cnhucXJpc3BsbWV0YmNleXFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNjAzNTcsImV4cCI6MjA5MTgzNjM1N30.GQm3JUk2jkHf_boqj_vTRusWqvhEN55lLG3tdPYnohw > ../logs/admin.log 2>&1"
timeout /t 3 /nobreak >nul

REM 3. 启动爬虫 (Python)
echo [3/3] 启动爬虫服务...
start "DaCong Spider" cmd /c "cd dacong-spider && python main.py > ../logs/spider.log 2>&1"
timeout /t 2 /nobreak >nul

echo.
echo ========================================
echo   所有服务已启动！
echo ========================================
echo.
echo   前台客户端: http://localhost:8081
echo   后台管理:   http://localhost:8080
echo   爬虫服务:   运行中 (查看 logs/spider.log)
echo.
echo   日志文件:
echo   - logs/client.log
echo   - logs/admin.log
echo   - logs/spider.log
echo.
echo   按任意键关闭所有服务...
pause >nul

REM 关闭所有服务
echo.
echo 正在关闭所有服务...
taskkill /FI "WINDOWTITLE eq DaCong Client*" /F >nul 2>&1
taskkill /FI "WINDOWTITLE eq DaCong Admin*" /F >nul 2>&1
taskkill /FI "WINDOWTITLE eq DaCong Spider*" /F >nul 2>&1
echo 所有服务已关闭。
