# 性能优化快速上手指南

## 快速开始

### 1. 前端优化使用

#### 骨架屏加载
```dart
// 在列表加载时使用
if (isLoading) {
  return ListView.builder(
    itemCount: 5,
    itemBuilder: (context, index) => ListItemSkeleton(),
  );
}
```

#### 优化图片加载
```dart
// 替换原有的 Image.network
OptimizedNetworkImage(
  imageUrl: content.imageUrl,
  width: 200,
  height: 200,
)
```

#### Toast 提示
```dart
// 成功提示
ToastHelper.showSuccess(context, '操作成功');

// 错误提示
ToastHelper.showError(context, '操作失败');
```

#### 错误处理
```dart
// 统一错误界面
if (state is ErrorState) {
  return ErrorRetryWidget(
    message: state.message,
    onRetry: () => bloc.add(RetryEvent()),
  );
}
```

### 2. API 优化使用

#### 应用数据库索引
```bash
cd dacong-api
supabase db push
```

#### 添加 API 限流
```typescript
// 在 Edge Function 中使用
import { createRateLimiter, RateLimitPresets } from './_shared/middleware/rate_limiter.ts';

const rateLimiter = createRateLimiter(RateLimitPresets.standard);

Deno.serve(async (req) => {
  const limitResponse = await rateLimiter(req);
  if (limitResponse) return limitResponse;
  
  // 你的业务逻辑
  return new Response('OK');
});
```

### 3. 爬虫优化使用

#### 批量写入
```python
from core.batch_writer import ContentBatchWriter

writer = ContentBatchWriter(supabase_client, batch_size=100)
await writer.start()

# 添加数据
await writer.add_content(
    title="标题",
    url="https://example.com",
    source_platform="github"
)

await writer.stop()
```

#### 性能监控
```python
from monitoring.spider_monitor import SpiderMonitor

monitor = SpiderMonitor("my_spider")
await monitor.start()

# 记录请求
monitor.record_request(success=True, response_time=0.5)

# 记录数据
monitor.record_item(success=True)

await monitor.stop()
```

### 4. 代码质量检查

#### 检查代码质量
```bash
./scripts/code_quality_check.sh
```

#### 自动修复问题
```bash
./scripts/fix_all.sh
```

## 性能提升预期

- 前端首屏加载速度提升 50%+
- API 查询响应时间减少 80%+
- 爬虫数据写入速度提升 10-20倍
- 整体用户体验显著改善

## 详细文档

查看完整优化报告: `docs/OPTIMIZATION.md`

## 注意事项

1. 前端必须使用 OptimizedNetworkImage 替代 Image.network
2. 所有 API 接口建议添加限流保护
3. 爬虫必须使用批量写入，避免单条插入
4. 提交代码前运行自动修复脚本

---

**快速上手完成！开始享受性能提升吧！**
