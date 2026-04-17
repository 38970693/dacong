# 中间件使用说明

## 性能监控中间件

### 使用方法

在 Supabase Function 中使用性能监控中间件：

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { performanceMiddleware } from '../_shared/middleware/performance.ts';

serve(async (req) => {
  return performanceMiddleware({
    slowThreshold: 1000,  // 慢请求阈值（毫秒）
    logToConsole: true,   // 是否输出到控制台
    logToDatabase: false, // 是否保存到数据库
  })(req, async (req) => {
    // 你的业务逻辑
    const data = await fetchData();
    
    return new Response(
      JSON.stringify({ success: true, data }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  });
});
```

### 配置选项

- `slowThreshold`: 慢请求阈值（毫秒），默认 1000ms
- `logToConsole`: 是否输出到控制台，默认 true
- `logToDatabase`: 是否保存到数据库，默认 false

### 响应头

中间件会在响应中添加以下头：

- `X-Response-Time`: 请求处理时间（毫秒）
- `X-Slow-Request`: 如果是慢请求，值为 'true'

### 日志格式

```json
{
  "type": "performance",
  "endpoint": "/api/contents",
  "method": "GET",
  "duration_ms": 234,
  "status": 200,
  "timestamp": "2026-04-17T12:00:00.000Z",
  "request_size": 0,
  "response_size": 1024,
  "level": "✅",
  "slow": false
}
```

### 性能统计

使用 `PerformanceStats` 类收集和分析性能指标：

```typescript
import { PerformanceStats } from '../_shared/middleware/performance.ts';

const stats = new PerformanceStats();

// 添加指标
stats.add(metric);

// 获取统计
const summary = stats.getStats();
console.log(summary);
// {
//   count: 100,
//   avg: 234.5,
//   min: 50,
//   max: 1200,
//   p50: 200,
//   p95: 800,
//   p99: 1100,
//   error_rate: 0.02
// }
```
