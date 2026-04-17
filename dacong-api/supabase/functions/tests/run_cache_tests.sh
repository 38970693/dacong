#!/bin/bash
# 运行 Redis 缓存测试

set -e

echo "=== Redis 缓存测试 ==="
echo ""

# 检查 Redis 连接
echo "[1/2] 检查 Redis 连接..."
if redis-cli -h localhost -p 6379 ping > /dev/null 2>&1; then
    echo "✓ Redis 连接正常"
else
    echo "✗ Redis 连接失败，请先启动 Redis"
    exit 1
fi

# 运行测试
echo ""
echo "[2/2] 运行测试..."
cd "$(dirname "$0")/.."
deno test --allow-net --allow-env tests/RedisCache.test.ts

echo ""
echo "=== 测试完成 ==="
