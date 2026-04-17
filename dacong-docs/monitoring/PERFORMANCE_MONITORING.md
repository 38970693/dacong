# 性能监控系统文档

## 概述

本文档描述大聪项目的性能监控架构、指标定义、告警规则和优化方法。

## 监控架构

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Flutter   │────▶│  Supabase   │────▶│  Database   │
│   Client    │     │  Functions  │     │  Metrics    │
└─────────────┘     └─────────────┘     └─────────────┘
       │                    │                    │
       │                    │                    │
       ▼                    ▼                    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Sentry    │     │   Console   │     │  Analytics  │
│  (前端监控)  │     │    Logs     │     │   Dashboard │
└─────────────┘     └─────────────┘     └─────────────┘

┌─────────────┐
│   Spider    │────▶ Performance Monitor ────▶ Logs
└─────────────┘
```

## 监控指标

### 1. API 性能指标

| 指标 | 说明 | 阈值 |
|------|------|------|
| `api_call_duration` | API 请求响应时间 | P95 < 1s |
| `api_error_rate` | API 错误率 | < 5% |
| `api_throughput` | API 吞吐量 | - |
| `api_request_size` | 请求体大小 | < 1MB |
| `api_response_size` | 响应体大小 | < 5MB |

### 2. 数据库性能指标

| 指标 | 说明 | 阈值 |
|------|------|------|
| `query_duration` | 查询执行时间 | < 1s |
| `slow_query_count` | 慢查询数量 | < 10/分钟 |
| `connection_count` | 数据库连接数 | < 100 |
| `cache_hit_rate` | 缓存命中率 | > 80% |

### 3. 前端性能指标

| 指标 | 说明 | 阈值 |
|------|------|------|
| `page_load_time` | 页面加载时间 | < 3s |
| `api_call_time` | API 调用时间 | < 2s |
| `frame_rate` | 帧率 | > 50 FPS |
| `memory_usage` | 内存使用 | < 200MB |

### 4. 爬虫性能指标

| 指标 | 说明 | 阈值 |
|------|------|------|
| `spider_duration` | 爬虫运行时间 | < 10分钟 |
| `spider_throughput` | 抓取速度 | > 0.5 items/s |
| `spider_error_rate` | 爬虫错误率 | < 10% |
| `spider_success_rate` | 爬虫成功率 | > 90% |

## 数据库表结构

```sql
CREATE TABLE performance_metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service VARCHAR(50) NOT NULL,           -- api, client, spider, database
  metric_type VARCHAR(50) NOT NULL,       -- api_call, page_load, spider_run, query
  metric_name VARCHAR(100) NOT NULL,      -- 具体的端点、页面或操作名称
  metric_value FLOAT NOT NULL,            -- 指标值（毫秒、秒等）
  tags JSONB,                             -- 额外的标签和元数据
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_performance_metrics_service ON performance_metrics(service);
CREATE INDEX idx_performance_metrics_created_at ON performance_metrics(created_at);
CREATE INDEX idx_performance_metrics_type ON performance_metrics(metric_type);
```

## 使用方法

### 后端 API 监控

在 Supabase Function 中使用性能中间件：

```typescript
import { performanceMiddleware } from '../_shared/middleware/performance.ts';

serve(async (req) => {
  return performanceMiddleware({
    slowThreshold: 1000,
    logToConsole: true,
  })(req, async (req) => {
    // 你的业务逻辑
    return new Response(JSON.stringify({ success: true }));
  });
});
```

### 前端监控

在 Flutter 应用中使用性能监控：

```dart
import 'package:dacong_client/core/performance/performance_monitor.dart';

// 初始化
PerformanceMonitor().initialize();

// 追踪页面加载
PerformanceMonitor().startPageLoad('HomePage');
// ... 页面加载逻辑
PerformanceMonitor().endPageLoad('HomePage');

// 追踪 API 调用
PerformanceMonitor().startApiCall('/api/contents');
// ... API 调用
PerformanceMonitor().endApiCall('/api/contents', success: true);
```

### 爬虫监控

在爬虫中使用性能监控：

```python
from monitoring.performance_monitor import performance_monitor

# 开始监控
performance_monitor.start_spider_run('weekly_spider')

# 记录抓取的条目
performance_monitor.record_item('weekly_spider', success=True)

# 结束监控
metric = performance_monitor.end_spider_run('weekly_spider')
```

## 告警规则

### 告警级别

- **CRITICAL（严重）**: 需要立即处理，影响用户体验
- **WARNING（警告）**: 需要关注，可能影响性能
- **INFO（信息）**: 仅记录，无需处理

### 告警规则配置

| 规则 | 级别 | 条件 | 处理建议 |
|------|------|------|----------|
| API 响应慢 | WARNING | P95 > 1s | 优化查询、添加缓存 |
| API 响应超慢 | CRITICAL | P95 > 5s | 立即优化或降级 |
| 错误率高 | CRITICAL | > 5% | 检查日志、修复 bug |
| 数据库慢查询 | WARNING | > 10次/分钟 | 添加索引、优化 SQL |
| 爬虫失败率高 | CRITICAL | > 10% | 检查网络、修复解析逻辑 |
| 前端页面加载慢 | WARNING | > 3s | 优化资源加载、代码分割 |
| 帧率低 | WARNING | < 30 FPS | 优化渲染、减少重绘 |

## 性能优化方法

### API 优化

1. **添加缓存**: 使用 Redis 缓存热点数据
2. **数据库优化**: 添加索引、优化查询
3. **分页**: 大数据集使用分页
4. **异步处理**: 耗时操作异步化
5. **CDN**: 静态资源使用 CDN

### 数据库优化

1. **索引优化**: 为常用查询字段添加索引
2. **查询优化**: 避免 N+1 查询、使用 JOIN
3. **连接池**: 使用连接池管理数据库连接
4. **读写分离**: 读写分离减轻主库压力
5. **分区表**: 大表使用分区

### 前端优化

1. **代码分割**: 按需加载代码
2. **图片优化**: 压缩图片、使用 WebP
3. **懒加载**: 图片和组件懒加载
4. **缓存**: 使用本地缓存
5. **减少重绘**: 优化渲染逻辑

### 爬虫优化

1. **并发控制**: 合理设置并发数
2. **重试机制**: 失败自动重试
3. **代理池**: 使用代理池避免封禁
4. **增量抓取**: 只抓取新内容
5. **错误处理**: 完善错误处理逻辑

## 故障排查指南

### API 响应慢

1. 检查数据库慢查询日志
2. 检查是否有 N+1 查询
3. 检查缓存是否生效
4. 检查网络延迟
5. 使用 APM 工具定位瓶颈

### 数据库慢查询

1. 使用 `EXPLAIN ANALYZE` 分析查询计划
2. 检查是否缺少索引
3. 检查是否有全表扫描
4. 优化 JOIN 顺序
5. 考虑分区或分表

### 前端页面加载慢

1. 使用 Chrome DevTools 分析加载时间
2. 检查网络请求瀑布图
3. 检查是否有阻塞渲染的资源
4. 优化首屏加载
5. 使用性能分析工具

### 爬虫失败率高

1. 检查网络连接
2. 检查目标网站是否变更
3. 检查是否被封禁
4. 检查解析逻辑是否正确
5. 增加重试和容错

## 性能分析工具

### 使用分析脚本

```bash
# 设置数据库连接
export DATABASE_URL="postgresql://user:pass@host:5432/db"

# 运行性能分析
./scripts/analyze_performance.sh
```

### 查询性能指标

```bash
# 使用 Supabase CLI
supabase functions invoke get-performance-metrics \
  --data '{
    "service": "api",
    "metric_type": "api_call",
    "start_date": "2026-04-17T00:00:00Z",
    "end_date": "2026-04-18T00:00:00Z"
  }'
```

## 最佳实践

1. **持续监控**: 建立持续监控机制，及时发现问题
2. **基线建立**: 建立性能基线，对比变化趋势
3. **定期审查**: 定期审查性能指标，优化瓶颈
4. **自动化告警**: 配置自动化告警，快速响应
5. **性能测试**: 上线前进行性能测试
6. **容量规划**: 根据监控数据进行容量规划
7. **文档更新**: 及时更新监控文档

## 参考资料

- [Supabase Performance Best Practices](https://supabase.com/docs/guides/performance)
- [Flutter Performance Best Practices](https://flutter.dev/docs/perf/best-practices)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [Sentry Performance Monitoring](https://docs.sentry.io/product/performance/)
