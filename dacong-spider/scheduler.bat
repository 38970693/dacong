@echo off
REM ================================================
REM AI 排行榜数据抓取 - Windows 定时任务脚本
REM ================================================
REM
REM 使用方法:
REM 1. 手动运行: scheduler.bat
REM 2. 添加到 Windows 任务计划程序:
REM    schtasks /create /tn "AI Rankings" /tr "path\to\scheduler.bat" /sc daily /st 08:00
REM
REM ================================================

cd /d "%~dp0"

echo ================================================
echo   AI 排行榜数据抓取
echo ================================================
echo.

python -X utf8 run_all_rankings.py --lmarena --aa --save-db

echo.
echo ================================================
echo   抓取完成！按任意键退出...
echo ================================================
pause >nul