# 快速开始指南

## 项目概述

本项目是一个基于 Supabase Edge Functions 的后端 API 系统，采用面向对象设计和分层架构，严格遵循 SOLID 原则。

## 技术栈

- **运行时**: Deno
- **数据库**: PostgreSQL (Supabase)
- **验证**: Zod
- **架构**: 分层架构 + 依赖注入

## 目录结构

```
dacong-api/supabase/functions/
├── _shared/                          # 共享代码
│   ├── core/
│   │   └── Container.ts              # 依赖注入容器
│   ├── domain/
│   │   ├── Content.ts                # 内容实体
│   │   ├── Recommendation.ts         # 推荐实体
│   │   └── UserFeedback.ts           # 反馈实体
│   ├── repositories/
│   │   ├── IContentRepository.ts
│   │   ├── IRecommendationRepository.ts
│   │   ├── IFeedbackRepository.ts
│   │   ├── SupabaseContentRepository.ts
│   │   ├── SupabaseRecommendationRepository.ts
│   │   └── SupabaseFeedbackRepository.ts
│   ├── services/
│   │   ├── ContentService.ts
│   │   ├── RecommendationService.ts
│   │   └── FeedbackService.ts
│   ├── dto/
│   │   ├── ApiResponse.ts
│   │   ├── GetRecommendationsRequest.ts
│   │   ├── GetContentDetailRequest.ts
│   │   ├── SubmitFeedbackRequest.ts
│   │   └── SearchContentRequest.ts
│   └── utils/
│       └── http.ts
├── get-recommendations/              # API 端点
├── get-content-detail/
├── submit-feedback/
├── search-content/
├── get-weekly-report/
└── tests/                            # 单元测试
```

## 快速开始

### 1. 环境准备

```bash
# 安装 Supabase CLI
npm install -g supabase

# 安装 Deno (如果还没有)
curl -fsSL https://deno.land/install.sh | sh
```

### 2. 配置环境变量

创建 `.env` 文件：

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### 3. 初始化数据库

```bash
# 链接到 Supabase 项目
supabase link --project-ref your-project-ref

# 应用数据库迁移（参考 dacong-docs/04-数据库设计.md）
supabase db push
```

### 4. 本地运行

```bash
# 启动本地 Edge Functions
supabase functions serve

# 测试 API
curl "http://localhost:54321/functions/v1/get-recommendations?scenario=coding"
```

### 5. 运行测试

```bash
# 运行所有测试
deno test --allow-all supabase/functions/tests/

# 运行特定测试
deno test --allow-all supabase/functions/tests/Content.test.ts
```

### 6. 部署到生产环境

```bash
# 部署所有函数
supabase functions deploy get-recommendations
supabase functions deploy get-content-detail
supabase functions deploy submit-feedback
supabase functions deploy search-content
supabase functions deploy get-weekly-report
```

## API 使用示例

### 1. 获取场景推荐

```bash
curl "https://your-project.supabase.co/functions/v1/get-recommendations?scenario=coding&language=zh&limit=10"
```

响应：
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "content_type": "recommendation",
      "title": "AI编程工具推荐",
      "summary": "最佳编程助手推荐",
      "content": { /* ... */ },
      "scenario": "coding",
      "view_count": 1000,
      "helpful_count": 800,
      "helpful_rate": 0.89,
      "published_at": "2026-04-17T10:00:00Z"
    }
  ],
  "error": null,
  "meta": {
    "total": 10,
    "scenario": "coding",
    "language": "zh"
  }
}
```

### 2. 获取内容详情

```bash
curl "https://your-project.supabase.co/functions/v1/get-content-detail?id=uuid&language=zh"
```

### 3. 提交用户反馈

```bash
curl -X POST "https://your-project.supabase.co/functions/v1/submit-feedback" \
  -H "Content-Type: application/json" \
  -d '{
    "contentId": "uuid",
    "isHelpful": true,
    "comment": "非常有用！"
  }'
```

### 4. 搜索内容

```bash
curl "https://your-project.supabase.co/functions/v1/search-content?query=AI工具&language=zh&limit=20"
```

### 5. 获取周报

```bash
curl "https://your-project.supabase.co/functions/v1/get-weekly-report?language=zh&limit=10"
```

## 开发指南

### 添加新的 API 端点

1. 创建新的 Edge Function 目录：
```bash
mkdir supabase/functions/your-new-endpoint
```

2. 创建 `index.ts`：
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { Container } from "../_shared/core/Container.ts";
import { corsResponse, successResponse, errorResponse } from "../_shared/utils/http.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return corsResponse();
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!
    );

    const container = Container.getInstance(supabase);
    const service = container.getContentService();

    // 你的业务逻辑
    const result = await service.yourMethod();

    return successResponse(result);
  } catch (error) {
    return errorResponse(error.message, 400);
  }
});
```

3. 部署：
```bash
supabase functions deploy your-new-endpoint
```

### 添加新的业务逻辑

在 Service 层添加新方法：

```typescript
// _shared/services/ContentService.ts
class ContentService {
  async getRelatedContent(id: string): Promise<Content[]> {
    const content = await this.contentRepository.findById(id);
    if (!content) return [];
    
    return await this.contentRepository.findByScenario(content.scenario);
  }
}
```

### 添加新的数据源

实现对应的 Repository 接口：

```typescript
// _shared/repositories/RedisContentRepository.ts
class RedisContentRepository implements IContentRepository {
  constructor(private readonly redis: RedisClient) {}
  
  async findById(id: string): Promise<Content | null> {
    const data = await this.redis.get(`content:${id}`);
    return data ? Content.fromDatabase(JSON.parse(data)) : null;
  }
}
```

在 Container 中注册：

```typescript
// _shared/core/Container.ts
private registerRepositories(): void {
  this.services.set(
    "IContentRepository",
    new RedisContentRepository(this.redis)
  );
}
```

## 常见问题

### Q: 如何调试 Edge Functions？

A: 使用 `console.log` 输出日志，然后查看 Supabase Dashboard 的 Logs 页面。

### Q: 如何处理 CORS 错误？

A: 确保在每个 Edge Function 中处理 OPTIONS 请求：
```typescript
if (req.method === "OPTIONS") {
  return corsResponse();
}
```

### Q: 如何添加认证？

A: 使用 Supabase Auth：
```typescript
const authHeader = req.headers.get("Authorization");
const { data: { user } } = await supabase.auth.getUser(
  authHeader.replace("Bearer ", "")
);
```

### Q: 如何优化性能？

A: 
1. 在数据库中添加索引
2. 使用 Redis 缓存热点数据
3. 实现批量查询
4. 使用 CDN 加速静态资源

## 相关文档

- [README.md](./README.md) - 项目概述和完整文档
- [ARCHITECTURE.md](./ARCHITECTURE.md) - 架构设计详解
- [openapi.yaml](./openapi.yaml) - API 文档
- [dacong-docs/03-系统架构设计.md](../dacong-docs/03-系统架构设计.md) - 系统架构
- [dacong-docs/04-数据库设计.md](../dacong-docs/04-数据库设计.md) - 数据库设计

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

MIT License
