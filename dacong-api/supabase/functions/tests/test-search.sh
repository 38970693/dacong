#!/bin/bash

# 搜索功能测试脚本
# 测试端到端搜索流程

SUPABASE_URL="${SUPABASE_URL:-http://localhost:54321}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"

echo "========================================="
echo "搜索功能测试"
echo "========================================="
echo ""

# 测试 1: 基本搜索
echo "测试 1: 基本搜索 (query=cursor)"
curl -s -X GET "${SUPABASE_URL}/functions/v1/search-content?q=cursor" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  | jq '.'
echo ""

# 测试 2: 带场景筛选的搜索
echo "测试 2: 场景筛选 (query=ai&scenario=coding)"
curl -s -X GET "${SUPABASE_URL}/functions/v1/search-content?q=ai&scenario=coding" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  | jq '.'
echo ""

# 测试 3: 带价格筛选的搜索
echo "测试 3: 价格筛选 (query=tool&is_free=true)"
curl -s -X GET "${SUPABASE_URL}/functions/v1/search-content?q=tool&is_free=true" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  | jq '.'
echo ""

# 测试 4: 带排序的搜索
echo "测试 4: 按浏览量排序 (query=ai&sort_by=viewCount)"
curl -s -X GET "${SUPABASE_URL}/functions/v1/search-content?q=ai&sort_by=viewCount" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  | jq '.'
echo ""

# 测试 5: 分页搜索
echo "测试 5: 分页 (query=ai&limit=5&offset=0)"
curl -s -X GET "${SUPABASE_URL}/functions/v1/search-content?q=ai&limit=5&offset=0" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  | jq '.'
echo ""

# 测试 6: 获取热门搜索
echo "测试 6: 获取热门搜索"
curl -s -X GET "${SUPABASE_URL}/functions/v1/get-hot-searches?limit=10" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  | jq '.'
echo ""

# 测试 7: 空查询（应该返回错误）
echo "测试 7: 空查询（预期错误）"
curl -s -X GET "${SUPABASE_URL}/functions/v1/search-content?q=" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  | jq '.'
echo ""

# 测试 8: 特殊字符过滤
echo "测试 8: 特殊字符过滤 (query=cursor@#$%)"
curl -s -X GET "${SUPABASE_URL}/functions/v1/search-content?q=cursor@%23%24%25" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  | jq '.'
echo ""

echo "========================================="
echo "测试完成"
echo "========================================="
