@echo off
chcp 65001 >nul
echo ========================================
echo   DaCong 快速测试脚本
echo ========================================
echo.

REM 检查服务是否运行
echo [1/4] 检查服务状态...
echo.

REM 测试前台客户端
echo 测试前台客户端 (http://localhost:8081)...
curl -s -o nul -w "状态码: %%{http_code}\n" http://localhost:8081 2>nul
if %errorlevel% neq 0 (
    echo [×] 前台客户端未运行
) else (
    echo [✓] 前台客户端运行中
)
echo.

REM 测试后台管理
echo 测试后台管理 (http://localhost:8080)...
curl -s -o nul -w "状态码: %%{http_code}\n" http://localhost:8080 2>nul
if %errorlevel% neq 0 (
    echo [×] 后台管理未运行
) else (
    echo [✓] 后台管理运行中
)
echo.

REM 测试 Supabase Edge Functions
echo [2/4] 测试 Supabase Edge Functions...
echo.

set SUPABASE_URL=https://twrxnqrisplmetbceyqm.supabase.co
set ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR3cnhucXJpc3BsbWV0YmNleXFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNjAzNTcsImV4cCI6MjA5MTgzNjM1N30.GQm3JUk2jkHf_boqj_vTRusWqvhEN55lLG3tdPYnohw

echo 测试 auth-login...
curl -s -o nul -w "状态码: %%{http_code}\n" ^
  -X POST "%SUPABASE_URL%/functions/v1/auth-login" ^
  -H "Authorization: Bearer %ANON_KEY%" ^
  -H "Content-Type: application/json" 2>nul
echo.

echo 测试 csrf-token...
curl -s -o nul -w "状态码: %%{http_code}\n" ^
  -X GET "%SUPABASE_URL%/functions/v1/csrf-token" ^
  -H "Authorization: Bearer %ANON_KEY%" 2>nul
echo.

echo 测试 admin-get-users...
curl -s -o nul -w "状态码: %%{http_code}\n" ^
  -X GET "%SUPABASE_URL%/functions/v1/admin-get-users" ^
  -H "Authorization: Bearer %ANON_KEY%" 2>nul
echo.

REM 检查数据库表
echo [3/4] 检查数据库表...
echo.
echo 请在 Supabase Dashboard 验证以下表是否存在：
echo   - admin_users
echo   - admin_logs
echo   - comment_reports
echo.

REM 检查日志文件
echo [4/4] 检查日志文件...
echo.

if exist "logs\client.log" (
    echo [✓] logs\client.log 存在
    echo 最后 5 行:
    powershell -Command "Get-Content logs\client.log -Tail 5"
) else (
    echo [×] logs\client.log 不存在
)
echo.

if exist "logs\admin.log" (
    echo [✓] logs\admin.log 存在
    echo 最后 5 行:
    powershell -Command "Get-Content logs\admin.log -Tail 5"
) else (
    echo [×] logs\admin.log 不存在
)
echo.

if exist "logs\spider.log" (
    echo [✓] logs\spider.log 存在
    echo 最后 5 行:
    powershell -Command "Get-Content logs\spider.log -Tail 5"
) else (
    echo [×] logs\spider.log 不存在
)
echo.

echo ========================================
echo   测试完成
echo ========================================
echo.
echo 如果发现问题，请查看对应的日志文件。
echo.
pause
