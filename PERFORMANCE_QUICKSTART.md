# 性能监控快速开始

## 1. 部署数据库迁移

```bash
cd dacong-api
supabase db push
```

## 2. 后端 API 集成

在任意 Supabase Function 中添加性能监控：

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { performanceMiddleware } from '../_shared/middleware/performance.ts';

serve(async (req) => {
  return performanceMiddleware({
    slowThreshold: 1000,  // 1秒阈值
    logToConsole: true,
  })(req, async (req) => {
    // 你的业务逻辑
    const data = { message: 'Hello' };
    return new Response(JSON.stringify(data));
  });
});
```

## 3. 前端集成

在 Flutter 应用启动时初始化：

```dart
import 'package:dacong_client/core/performance/performance_monitor.dart';

void main() {
  // 初始化性能监控
  PerformanceMonitor().initialize();
  
  runApp(MyApp());
}
```

在页面中使用：

```dart
class HomePage extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    PerformanceMonitor().startPageLoad('HomePage');
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    PerformanceMonitor().endPageLoad('HomePage');
  }
}
```

## 4. 爬虫集成

在爬虫代码中添加监控：

```python
from monitoring.performance_monitor import performance_monitor

def run_weekly_spider():
    # 开始监控
    performance_monitor.start_spider_run('weekly_spider')
    
    try:
        for item in scrape_items():
            # 记录成功
            performance_monitor.record_item('weekly_spider', success=True)
            save_item(item)
    except Exception as e:
        # 记录失败
        performance_monitor.record_item('weekly_spider', success=False)
        raise
    finally:
        # 结束监控
        metric = performance_monitor.end_spider_run('weekly_spider')
        print(f"完成: {metric.items_count} 条，耗时 {metric.duration_seconds:.2f}s")
```

## 5. 查看性能数据

### 使用分析脚本

```bash
export DATABASE_URL="postgresql://user:pass@host:5432/db"
./scripts/analyze_performance.sh
```

### 使用 SQL 查询

```sql
-- 查看最近 1 小时的 API 性能
SELECT * FROM get_performance_stats('1h');

-- 查看慢查询
SELECT * FROM get_slow_queries_stats('24h');

-- 查看性能摘要
SELECT * FROM performance_summary
WHERE hour > NOW() - INTERVAL '24 hours'
ORDER BY hour DESC;
```

### 使用 API 查询

```bash
curl -X POST https://your-project.supabase.co/functions/v1/get-performance-metrics \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "service": "api",
    "metric_type": "api_call",
    "start_date": "2026-04-17T00:00:00Z",
    "limit": 100
  }'
```

## 6. 告警配置

性能告警会自动触发，查看告警：

```sql
SELECT * FROM alerts
WHERE alert_type = 'performance'
ORDER BY created_at DESC
LIMIT 10;
```

## 7. 性能优化流程

1. **发现问题**: 通过告警或定期分析发现性能瓶颈
2. **定位原因**: 使用 `analyze_performance.sh` 分析具体原因
3. **实施优化**: 根据建议优化代码或配置
4. **验证效果**: 对比优化前后的性能指标

## 常见问题

### Q: 如何调整告警阈值？

修改 `dacong-api/supabase/migrations/20260418000000_performance_monitoring.sql` 中的触发器：

```sql
-- 修改慢请求阈值为 5 秒
IF NEW.metric_type = 'api_call' AND NEW.metric_value > 5000 THEN
```

### Q: 如何清理历史数据？

手动执行清理函数：

```sql
SELECT cleanup_old_performance_metrics();
```

或配置定时任务（使用 pg_cron）：

```sql
SELECT cron.schedule('cleanup-performance', '0 2 * * *', 
  'SELECT cleanup_old_performance_metrics()');
```

### Q: 性能监控会影响性能吗？

- 控制台日志：影响极小（< 1ms）
- 数据库持久化：建议异步批量写入
- Sentry 上报：异步执行，不阻塞主流程

## 下一步

- 查看完整文档: `dacong-docs/monitoring/PERFORMANCE_MONITORING.md`
- 配置告警规则: `dacong-docs/monitoring/PERFORMANCE_ALERTS.md`
- 运行测试: `bash scripts/test_performance_monitoring.sh`
