# Sentry 集成说明 - Supabase Edge Functions

## 环境变量配置

在 Supabase 项目中配置以下环境变量：

```bash
# 在 Supabase Dashboard 中设置
SENTRY_DSN=your_sentry_dsn_here
ENVIRONMENT=production  # 或 development
```

或使用 Supabase CLI：

```bash
supabase secrets set SENTRY_DSN=your_sentry_dsn_here
supabase secrets set ENVIRONMENT=production
```

## 使用方法

### 1. 基础集成（推荐）

使用 `withSentry` 包装器自动处理错误和性能追踪：

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { initSentry, withSentry } from "../_shared/utils/sentry.ts";

// 初始化 Sentry
initSentry({
  functionName: "my-function",
});

serve(
  withSentry(
    async (req) => {
      // 你的业务逻辑
      return new Response("OK");
    },
    {
      functionName: "my-function",
      captureErrors: true,
    }
  )
);
```

### 2. 手动错误捕获

```typescript
import { captureException, captureMessage } from "../_shared/utils/sentry.ts";

try {
  // 业务逻辑
} catch (error) {
  captureException(error, "操作失败", "error");
  throw error;
}

// 捕获警告消息
captureMessage("用户尝试访问受限资源", "warning", {
  userId: user.id,
  resource: resourceId,
});
```

### 3. 添加上下文信息

```typescript
import { setUser, setTag, setContext, addBreadcrumb } from "../_shared/utils/sentry.ts";

// 设置用户信息
setUser({
  id: user.id,
  email: user.email,
  username: user.name,
});

// 设置标签
setTag("feature", "content-detail");
setTag("version", "1.0.0");

// 设置上下文
setContext("business", {
  contentId: contentId,
  contentType: "article",
});

// 添加面包屑
addBreadcrumb({
  message: "开始加载内容",
  category: "content",
  level: "info",
  data: { contentId },
});
```

### 4. 性能追踪

```typescript
import { startTransaction } from "../_shared/utils/sentry.ts";

const transaction = startTransaction(
  "load-content",
  "db.query",
  "从数据库加载内容"
);

try {
  const content = await loadContent();
  transaction.setStatus("ok");
} catch (error) {
  transaction.setStatus("internal_error");
  throw error;
} finally {
  transaction.finish();
}
```

### 5. 专用错误报告

```typescript
import {
  reportDatabaseError,
  reportExternalApiError,
  reportPerformanceIssue,
} from "../_shared/utils/sentry.ts";

// 报告数据库错误
try {
  await supabase.from("content").select("*");
} catch (error) {
  reportDatabaseError(error, "SELECT * FROM content");
}

// 报告外部 API 错误
try {
  const response = await fetch("https://api.example.com/data");
} catch (error) {
  reportExternalApiError(error, "https://api.example.com/data", "GET", 500);
}

// 报告性能问题
const startTime = Date.now();
await slowOperation();
const duration = Date.now() - startTime;
reportPerformanceIssue("slow-operation", duration, 3000);
```

## 功能特性

- ✅ 自动捕获未处理的异常
- ✅ 自动记录 HTTP 请求信息
- ✅ 性能追踪和监控
- ✅ 面包屑记录
- ✅ 敏感信息自动过滤
- ✅ 环境标签
- ✅ 用户上下文
- ✅ 自定义标签和上下文

## 集成示例

查看已集成的 Edge Functions：
- `get-content-detail/index.ts` - 完整集成示例

## 注意事项

1. 生产环境必须配置 `SENTRY_DSN`
2. 敏感信息（password, token, api_key, authorization）会自动过滤
3. 健康检查请求不会记录到 Sentry
4. 采样率已针对生产环境优化（20%）
5. 使用 `withSentry` 包装器可自动处理大部分场景
