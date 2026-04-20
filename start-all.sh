#!/bin/bash

# DaCong 一键启动脚本 (Linux/Mac)

set -e

echo "========================================"
echo "  DaCong 一键启动脚本"
echo "========================================"
echo

# 检查必要的工具
command -v flutter >/dev/null 2>&1 || { echo "[错误] 未找到 Flutter"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "[错误] 未找到 Node.js"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "[错误] 未找到 Python"; exit 1; }

echo "[✓] 环境检查通过"
echo

# 创建日志目录
mkdir -p logs

echo "========================================"
echo "  启动服务..."
echo "========================================"
echo

# Supabase 配置
SUPABASE_URL="https://twrxnqrisplmetbceyqm.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR3cnhucXJpc3BsbWV0YmNleXFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNjAzNTcsImV4cCI6MjA5MTgzNjM1N30.GQm3JUk2jkHf_boqj_vTRusWqvhEN55lLG3tdPYnohw"

# 1. 启动前台客户端
echo "[1/3] 启动前台客户端 (http://localhost:8081)..."
cd dacong-client
flutter run -d chrome \
  --web-port=8081 \
  --dart-define=DEV_MODE=true \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  > ../logs/client.log 2>&1 &
CLIENT_PID=$!
cd ..
sleep 3

# 2. 启动后台管理
echo "[2/3] 启动后台管理 (http://localhost:8080)..."
cd dacong-admin
flutter run -d chrome \
  --web-port=8080 \
  --dart-define=DEV_MODE=true \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  > ../logs/admin.log 2>&1 &
ADMIN_PID=$!
cd ..
sleep 3

# 3. 启动爬虫
echo "[3/3] 启动爬虫服务..."
cd dacong-spider
python3 main.py > ../logs/spider.log 2>&1 &
SPIDER_PID=$!
cd ..
sleep 2

echo
echo "========================================"
echo "  所有服务已启动！"
echo "========================================"
echo
echo "  前台客户端: http://localhost:8081"
echo "  后台管理:   http://localhost:8080"
echo "  爬虫服务:   运行中 (PID: $SPIDER_PID)"
echo
echo "  进程 ID:"
echo "  - Client: $CLIENT_PID"
echo "  - Admin:  $ADMIN_PID"
echo "  - Spider: $SPIDER_PID"
echo
echo "  日志文件:"
echo "  - logs/client.log"
echo "  - logs/admin.log"
echo "  - logs/spider.log"
echo
echo "  按 Ctrl+C 关闭所有服务..."

# 捕获 Ctrl+C 信号
trap "echo; echo '正在关闭所有服务...'; kill $CLIENT_PID $ADMIN_PID $SPIDER_PID 2>/dev/null; echo '所有服务已关闭。'; exit 0" INT

# 等待
wait
