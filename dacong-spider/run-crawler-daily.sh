#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# DaCong 数据底座 · 每日爬虫运行脚本
# 作用：建/复用 venv → 跑 4 大领域爬虫 → 刷新 GitHub 飙升榜
# 用法：bash run-crawler-daily.sh
# 建议：crontab 每日执行，例如 0 6 * * *  cd .../dacong-spider && bash run-crawler-daily.sh
# ═══════════════════════════════════════════════════════════
set -euo pipefail
cd "$(dirname "$0")"

VENV=".venv"
PY="$VENV/bin/python"
PIP="$VENV/bin/pip"

if [ ! -x "$PY" ]; then
  echo "创建虚拟环境 $VENV 并安装依赖 ..."
  python3 -m venv "$VENV"
  "$PIP" install -r requirements.txt
fi

run() {
  echo "▶ 运行爬虫: $1"
  "$PY" main.py --spider "$1" || echo "  ⚠️ $1 运行失败，继续下一个"
}

# —— 四大领域 ——
run arxiv              # AI 资讯（arXiv cs.AI/cs.CL）
run ai_news_rss        # AI 资讯（媒体 RSS）
run github             # GitHub 快速涨星
run artificial_analysis  # 大模型能力 + 评测分数
run arena              # 大模型评测（LM Arena ELO）

# —— 计算层：GitHub 飙升榜（需先部署 compute-rising-stars）——
echo "▶ 刷新 GitHub 飙升榜 (compute-rising-stars) ..."
supabase functions invoke compute-rising-stars 2>/dev/null \
  || echo "  ⚠️ compute-rising-stars 未部署，跳过（先运行 deploy-data-foundation.sh）"

echo "✅ 完成"
