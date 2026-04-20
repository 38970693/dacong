@echo off
cd /d "%~dp0"
echo Starting DaCong Admin in DEV MODE...
echo.

REM 启动应用
flutter run -d chrome ^
  --dart-define=DEV_MODE=true ^
  --dart-define=SUPABASE_URL=https://twrxnqrisplmetbceyqm.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR3cnhucXJpc3BsbWV0YmNleXFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNjAzNTcsImV4cCI6MjA5MTgzNjM1N30.GQm3JUk2jkHf_boqj_vTRusWqvhEN55lLG3tdPYnohw

pause
