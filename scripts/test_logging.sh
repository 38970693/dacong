#!/bin/bash

set -e

echo "🧪 测试日志聚合系统..."

# 检查服务是否运行
if ! docker-compose -f docker-compose.logging.yml ps | grep -q "Up"; then
    echo "❌ 日志聚合服务未运行，请先运行 ./scripts/setup_logging.sh"
    exit 1
fi

# 生成测试日志
echo "📝 生成测试日志..."

# API 测试日志
cat > logs/api/test.log << EOF
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","level":"INFO","service":"dacong-api","function":"recommend","message":"Recommendation generated","context":{"user_id":"test-user-1","duration_ms":150}}
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","level":"ERROR","service":"dacong-api","function":"recommend","message":"Failed to generate recommendation","context":{"user_id":"test-user-2"},"error":{"type":"DatabaseError","message":"Connection timeout"}}
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","level":"WARN","service":"dacong-api","function":"auth","message":"Authentication failed","context":{"ip":"192.168.1.1"}}
EOF

# 爬虫测试日志
cat > logs/spider/test.log << EOF
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","level":"INFO","service":"dacong-spider","module":"xiaohongshu","message":"Scrape started","context":{"url":"https://example.com"}}
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","level":"INFO","service":"dacong-spider","module":"xiaohongshu","message":"Scrape completed","context":{"url":"https://example.com","items_count":10,"duration_ms":500}}
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","level":"ERROR","service":"dacong-spider","module":"douyin","message":"Scrape failed","context":{"url":"https://example.com"},"error":{"type":"NetworkError","message":"Connection refused"}}
EOF

# 客户端测试日志
cat > logs/client/test.log << EOF
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","level":"INFO","service":"dacong-client","module":"HomeScreen","message":"Page view","context":{"screen":"HomeScreen","event_type":"page_view"}}
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","level":"DEBUG","service":"dacong-client","module":"ApiClient","message":"API request","context":{"method":"GET","path":"/api/recommendations"}}
{"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","level":"ERROR","service":"dacong-client","module":"ApiClient","message":"API request failed","context":{"method":"POST","path":"/api/submit"},"error":{"type":"NetworkException","message":"No internet connection"}}
EOF

echo "✅ 测试日志已生成"

# 等待 Promtail 采集日志
echo "⏳ 等待 Promtail 采集日志（10秒）..."
sleep 10

# 验证日志是否被采集
echo "🔍 验证日志采集..."

# 查询 Loki
QUERY_RESULT=$(curl -s -G "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={service=~"dacong-.*"}' \
  --data-urlencode 'limit=10' | jq -r '.data.result | length')

if [ "$QUERY_RESULT" -gt 0 ]; then
    echo "✅ 日志采集成功！找到 $QUERY_RESULT 条日志流"
else
    echo "❌ 日志采集失败，未找到日志"
    echo "检查 Promtail 日志："
    docker-compose -f docker-compose.logging.yml logs promtail | tail -20
    exit 1
fi

# 测试不同的查询
echo ""
echo "📊 测试日志查询..."

echo "1. 查询错误日志："
curl -s -G "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={service=~"dacong-.*"} |= "ERROR"' \
  --data-urlencode 'limit=5' | jq -r '.data.result[].values[][1]' | head -3

echo ""
echo "2. 查询 API 日志："
curl -s -G "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={service="dacong-api"}' \
  --data-urlencode 'limit=5' | jq -r '.data.result[].values[][1]' | head -3

echo ""
echo "3. 查询爬虫日志："
curl -s -G "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={service="dacong-spider"}' \
  --data-urlencode 'limit=5' | jq -r '.data.result[].values[][1]' | head -3

echo ""
echo "🎉 日志聚合系统测试完成！"
echo ""
echo "📊 访问 Grafana 查看日志："
echo "  http://localhost:3000"
echo ""
echo "💡 使用以下 LogQL 查询测试日志："
echo "  {service=~\"dacong-.*\"}"
echo "  {service=\"dacong-api\"} |= \"ERROR\""
echo "  {service=\"dacong-spider\"} | json | items_count > 0"
echo ""
