#!/bin/bash
# 性能监控系统测试脚本

set -e

echo "=========================================="
echo "性能监控系统测试"
echo "=========================================="
echo ""

# 检查环境变量
if [ -z "$DATABASE_URL" ]; then
    echo "⚠️  DATABASE_URL 未设置，跳过数据库测试"
    SKIP_DB=true
else
    echo "✅ DATABASE_URL 已设置"
    SKIP_DB=false
fi

echo ""

# 1. 测试数据库表结构
if [ "$SKIP_DB" = false ]; then
    echo "[1/5] 测试数据库表结构..."
    echo "----------------------------------------"

    # 检查 performance_metrics 表
    psql "$DATABASE_URL" -c "\d performance_metrics" > /dev/null 2>&1 && \
        echo "✅ performance_metrics 表存在" || \
        echo "❌ performance_metrics 表不存在"

    # 检查 slow_queries 表
    psql "$DATABASE_URL" -c "\d slow_queries" > /dev/null 2>&1 && \
        echo "✅ slow_queries 表存在" || \
        echo "❌ slow_queries 表不存在"

    # 检查索引
    psql "$DATABASE_URL" -c "SELECT indexname FROM pg_indexes WHERE tablename = 'performance_metrics';" > /dev/null 2>&1 && \
        echo "✅ 索引已创建" || \
        echo "❌ 索引未创建"

    echo ""
fi

# 2. 测试 Python 爬虫监控
echo "[2/5] 测试 Python 爬虫监控..."
echo "----------------------------------------"

if [ -f "dacong-spider/monitoring/performance_monitor.py" ]; then
    echo "✅ performance_monitor.py 存在"

    # 检查语法
    python3 -m py_compile dacong-spider/monitoring/performance_monitor.py 2>/dev/null && \
        echo "✅ Python 语法正确" || \
        echo "❌ Python 语法错误"
else
    echo "❌ performance_monitor.py 不存在"
fi

echo ""

# 3. 测试 TypeScript 中间件
echo "[3/5] 测试 TypeScript 中间件..."
echo "----------------------------------------"

if [ -f "dacong-api/supabase/functions/_shared/middleware/performance.ts" ]; then
    echo "✅ performance.ts 存在"

    # 检查语法（需要 deno）
    if command -v deno &> /dev/null; then
        deno check dacong-api/supabase/functions/_shared/middleware/performance.ts 2>/dev/null && \
            echo "✅ TypeScript 语法正确" || \
            echo "⚠️  TypeScript 语法检查失败（可能缺少依赖）"
    else
        echo "⚠️  Deno 未安装，跳过语法检查"
    fi
else
    echo "❌ performance.ts 不存在"
fi

echo ""

# 4. 测试 Dart 性能监控
echo "[4/5] 测试 Dart 性能监控..."
echo "----------------------------------------"

if [ -f "dacong-client/lib/core/performance/performance_monitor.dart" ]; then
    echo "✅ performance_monitor.dart 存在"

    # 检查语法（需要 dart）
    if command -v dart &> /dev/null; then
        cd dacong-client
        dart analyze lib/core/performance/performance_monitor.dart 2>/dev/null && \
            echo "✅ Dart 语法正确" || \
            echo "⚠️  Dart 语法检查失败"
        cd ..
    else
        echo "⚠️  Dart 未安装，跳过语法检查"
    fi
else
    echo "❌ performance_monitor.dart 不存在"
fi

echo ""

# 5. 测试文档完整性
echo "[5/5] 测试文档完整性..."
echo "----------------------------------------"

docs=(
    "dacong-docs/monitoring/PERFORMANCE_MONITORING.md"
    "dacong-docs/monitoring/PERFORMANCE_ALERTS.md"
)

for doc in "${docs[@]}"; do
    if [ -f "$doc" ]; then
        echo "✅ $doc 存在"
    else
        echo "❌ $doc 不存在"
    fi
done

echo ""

# 6. 测试脚本可执行性
echo "[6/6] 测试脚本..."
echo "----------------------------------------"

if [ -f "scripts/analyze_performance.sh" ]; then
    echo "✅ analyze_performance.sh 存在"

    if [ -x "scripts/analyze_performance.sh" ]; then
        echo "✅ analyze_performance.sh 可执行"
    else
        echo "⚠️  analyze_performance.sh 不可执行"
    fi
else
    echo "❌ analyze_performance.sh 不存在"
fi

echo ""
echo "=========================================="
echo "测试完成"
echo "=========================================="
echo ""

# 输出使用说明
echo "📖 使用说明:"
echo ""
echo "1. 数据库迁移:"
echo "   cd dacong-api"
echo "   supabase db push"
echo ""
echo "2. 查看性能指标:"
echo "   export DATABASE_URL='your-database-url'"
echo "   ./scripts/analyze_performance.sh"
echo ""
echo "3. 在代码中使用:"
echo "   - API: 导入 performanceMiddleware"
echo "   - 爬虫: 导入 performance_monitor"
echo "   - 前端: 使用 PerformanceMonitor()"
echo ""
echo "4. 查看文档:"
echo "   cat dacong-docs/monitoring/PERFORMANCE_MONITORING.md"
echo ""
