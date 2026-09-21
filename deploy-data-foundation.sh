#!/usr/bin/env bash
# ═══════════════════════════════════════════════
# DaCong 数据底座部署（方案 A）
# 作用：应用 3 个数据底座迁移 + 部署 6 个 Edge Functions
# 重要：只应用 00001/00002/00003（数据底座相关），
#       不触碰仓库历史 40+ 迁移，避免对已漂移的线上库造成意外变动。
# 用法：
#   export DATABASE_URL="postgresql://postgres:[密码]@db.<ref>.supabase.co:5432/postgres"
#   bash deploy-data-foundation.sh
# ═══════════════════════════════════════════════
set -euo pipefail
cd "$(dirname "$0")"

MIG_DIR="dacong-api/supabase/migrations"
MIGS=(
  20260807_00001_rising_stars.sql
  20260807_00002_model_evaluations.sql
  20260808_00003_schema_reconcile.sql
)

echo "=== [1/2] 应用数据底座迁移 ==="
if [ -n "${DATABASE_URL:-}" ]; then
  for m in "${MIGS[@]}"; do
    echo "  → $m"
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$MIG_DIR/$m"
  done
  echo "  迁移完成 ✅"
else
  echo "⚠️ 未设置 DATABASE_URL，请手动在 Supabase Dashboard → SQL Editor 依次执行："
  for m in "${MIGS[@]}"; do echo "   - $MIG_DIR/$m"; done
  echo "   （三个文件均为幂等，可重复执行）"
fi

echo "=== [2/2] 部署 Edge Functions ==="
if command -v supabase >/dev/null 2>&1; then
  cd dacong-api/supabase/functions
  for fn in compute-rising-stars get-rising-stars get-model-evaluations aggregate-evaluations get-model-comparison get-ai-news; do
    echo "  → $fn"
    supabase functions deploy "$fn"
  done
  echo "  函数部署完成 ✅"
else
  echo "⚠️ 未检测到 supabase CLI。"
  echo "  请在 Dashboard → Edge Functions 手动部署 dacong-api/supabase/functions/ 下这 6 个目录："
  echo "  compute-rising-stars get-rising-stars get-model-evaluations aggregate-evaluations get-model-comparison get-ai-news"
fi

echo "完成。"
