@echo off
REM ═══════════════════════════════════════════════════════════
REM DaCong 数据底座 · 每日爬虫运行脚本（Windows）
REM 作用：建/复用 venv → 跑 4 大领域爬虫 → 刷新 GitHub 飙升榜
REM 用法：run-crawler-daily.bat
REM ═══════════════════════════════════════════════════════════
cd /d "%~dp0"

set VENV=.venv
if not exist "%VENV%\Scripts\python.exe" (
  echo 创建虚拟环境 %VENV% 并安装依赖 ...
  python -m venv %VENV%
  %VENV%\Scripts\pip install -r requirements.txt
)

call :run arxiv
call :run ai_news_rss
call :run github
call :run artificial_analysis
call :run arena

echo 刷新 GitHub 飙升榜 ...
supabase functions invoke compute-rising-stars 2>nul || echo skipped (未部署 compute-rising-stars)
echo 完成
goto :eof

:run
echo ^>^> 运行爬虫: %1
%VENV%\Scripts\python.exe main.py --spider %1 || echo warn: %1 失败
goto :eof
