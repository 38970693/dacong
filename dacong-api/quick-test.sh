#!/bin/bash

echo "🧪 快速测试新增功能"
echo "=================="

# 测试认证函数
echo ""
echo "1️⃣ 测试认证函数"
cd supabase/functions/tests
deno test auth.test.ts --allow-net --allow-env --allow-read

# 测试收藏函数
echo ""
echo "2️⃣ 测试收藏函数"
deno test favorites.test.ts --allow-net --allow-env --allow-read

# 测试管理函数
echo ""
echo "3️⃣ 测试管理函数"
deno test admin.test.ts --allow-net --allow-env --allow-read

echo ""
echo "✅ 测试完成"
