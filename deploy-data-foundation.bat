@echo off
REM ═══════════════════════════════════════════════
REM DaCong 数据底座部署（方案 A，Windows）
REM 作用：应用 3 个数据底座迁移 + 部署 6 个 Edge Functions
REM 重要：只应用 00001/00002/00003，不触碰历史 40+ 迁移
REM 用法：先设置 DATABASE_URL 环境变量（Supabase 连接串），再运行本脚本
REM   set DATABASE_URL=postgresql://postgres:[密码]@db.^<ref^>.supabase.co:5432/postgres
REM   deploy-data-foundation.bat
REM ═══════════════════════════════════════════════
cd /d "%~dp0"

set MIG_DIR=dacong-api/supabase/migrations

echo === [1/2] 应用数据底座迁移 ===
if not "%DATABASE_URL%"=="" (
  psql "%DATABASE_URL%" -v ON_ERROR_STOP=1 -f %MIG_DIR%\20260807_00001_rising_stars.sql
  psql "%DATABASE_URL%" -v ON_ERROR_STOP=1 -f %MIG_DIR%\20260807_00002_model_evaluations.sql
  psql "%DATABASE_URL%" -v ON_ERROR_STOP=1 -f %MIG_DIR%\20260808_00003_schema_reconcile.sql
  echo 迁移完成 ✅
) else (
  echo ⚠️ 未设置 DATABASE_URL，请手动在 Supabase Dashboard → SQL Editor 依次执行：
  echo   - %MIG_DIR%\20260807_00001_rising_stars.sql
  echo   - %MIG_DIR%\20260807_00002_model_evaluations.sql
  echo   - %MIG_DIR%\20260808_00003_schema_reconcile.sql
  echo   （三个文件均为幂等，可重复执行）
)

echo === [2/2] 部署 Edge Functions ===
where supabase >nul 2>nul
if not errorlevel 1 (
  cd dacong-api/supabase/functions
  for %%f in (compute-rising-stars get-rising-stars get-model-evaluations aggregate-evaluations get-model-comparison get-ai-news) do (
    echo   -^> %%f
    supabase functions deploy %%f
  )
  echo 函数部署完成 ✅
) else (
  echo ⚠️ 未检测到 supabase CLI。
  echo   请在 Dashboard → Edge Functions 手动部署 dacong-api/supabase/functions/ 下这 6 个目录：
  echo   compute-rising-stars get-rising-stars get-model-evaluations aggregate-evaluations get-model-comparison get-ai-news
)

echo 完成。
