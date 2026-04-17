# 架构设计文档

## 设计思路

本项目采用**领域驱动设计（DDD）**和**分层架构**，将系统划分为四个核心层次：

### 1. 领域层 (Domain Layer)

**职责**: 封装业务实体和业务规则

**核心实体**:
- `Content`: 内容实体，包含内容的所有属性和业务方法
- `Recommendation`: 推荐实体，表示场景推荐配置
- `UserFeedback`: 用户反馈实体，表示用户对内容的评价

**设计原则**:
- **不可变性**: 所有实体都是不可变的，修改操作返回新实例
- **业务规则封装**: 业务逻辑（如计算有用率、判断是否热门）封装在实体内部
- **自包含**: 实体包含所有必要的数据和行为

**示例**:
```typescript
class Content {
  // 不可变属性
  constructor(
    public readonly id: string,
    public readonly titleZh: string,
    // ...
  ) {}

  // 业务方法
  incrementViewCount(): Content {
    // 返回新实例，不修改原对象
    return new Content(/* ... */, this.viewCount + 1, /* ... */);
  }

  get helpfulRate(): number | null {
    // 业务规则封装
    const total = this.helpfulCount + this.unhelpfulCount;
    return total > 0 ? this.helpfulCount / total : null;
  }
}
```

### 2. 仓储层 (Repository Layer)

**职责**: 封装数据访问逻辑，提供统一的数据访问接口

**设计模式**: Repository Pattern

**核心接口**:
- `IContentRepository`: 内容数据访问接口
- `IRecommendationRepository`: 推荐数据访问接口
- `IFeedbackRepository`: 反馈数据访问接口

**实现类**:
- `SupabaseContentRepository`: Supabase 实现
- `SupabaseRecommendationRepository`: Supabase 实现
- `SupabaseFeedbackRepository`: Supabase 实现

**设计原则**:
- **接口隔离**: 每个仓储接口只包含相关的方法
- **依赖倒置**: 上层依赖接口，不依赖具体实现
- **可替换性**: 可以轻松切换数据源（Supabase → MongoDB → MySQL）

**示例**:
```typescript
// 接口定义
interface IContentRepository {
  findById(id: string): Promise<Content | null>;
  findByScenario(scenario: Scenario): Promise<Content[]>;
}

// Supabase 实现
class SupabaseContentRepository implements IContentRepository {
  constructor(private readonly supabase: SupabaseClient) {}
  
  async findById(id: string): Promise<Content | null> {
    const { data } = await this.supabase
      .from("published_content")
      .select("*")
      .eq("id", id)
      .single();
    return data ? Content.fromDatabase(data) : null;
  }
}

// 未来可以添加其他实现
class MongoContentRepository implements IContentRepository {
  // MongoDB 实现
}
```

### 3. 服务层 (Service Layer)

**职责**: 编排业务逻辑，协调多个仓储和实体

**核心服务**:
- `ContentService`: 内容相关业务逻辑
- `RecommendationService`: 推荐相关业务逻辑
- `FeedbackService`: 反馈相关业务逻辑

**设计原则**:
- **单一职责**: 每个服务只负责一个业务领域
- **依赖注入**: 通过构造函数注入依赖
- **事务协调**: 处理跨多个仓储的业务逻辑

**示例**:
```typescript
class ContentService {
  constructor(private readonly contentRepository: IContentRepository) {}

  async getContentDetail(id: string, incrementView = true): Promise<Content | null> {
    // 1. 获取内容
    const content = await this.contentRepository.findById(id);
    if (!content) return null;

    // 2. 增加浏览次数（业务逻辑）
    if (incrementView) {
      await this.contentRepository.incrementViewCount(id);
    }

    return content;
  }
}

class FeedbackService {
  constructor(
    private readonly feedbackRepository: IFeedbackRepository,
    private readonly contentRepository: IContentRepository
  ) {}

  async submitFeedback(/* ... */): Promise<{ success: boolean; error?: string }> {
    // 1. 验证内容是否存在
    const content = await this.contentRepository.findById(contentId);
    if (!content) return { success: false, error: "Content not found" };

    // 2. 检查是否已反馈
    const hasSubmitted = await this.feedbackRepository.hasUserFeedback(contentId, userId);
    if (hasSubmitted) return { success: false, error: "Already submitted" };

    // 3. 创建反馈
    const feedback = await this.feedbackRepository.create(/* ... */);
    return { success: true, feedback };
  }
}
```

### 4. API 层 (Edge Functions)

**职责**: 处理 HTTP 请求，调用服务层，返回响应

**核心端点**:
- `get-recommendations`: 获取场景推荐
- `get-content-detail`: 获取内容详情
- `submit-feedback`: 提交用户反馈
- `search-content`: 搜索内容
- `get-weekly-report`: 获取周报

**设计原则**:
- **薄层**: 只负责请求解析和响应格式化
- **统一响应**: 使用 `ApiResponse` 统一响应格式
- **输入验证**: 使用 Zod 验证所有输入

**示例**:
```typescript
serve(async (req) => {
  try {
    // 1. 验证请求方法
    validateMethod(req, ["GET"]);

    // 2. 初始化依赖
    const supabase = createClient(/* ... */);
    const container = Container.getInstance(supabase);
    const contentService = container.getContentService();

    // 3. 解析和验证参数
    const params = getQueryParams(req);
    const validatedData = GetRecommendationsRequestSchema.parse(params);

    // 4. 调用服务层
    const recommendations = await contentService.getRecommendationsByScenario(
      validatedData.scenario,
      validatedData.limit
    );

    // 5. 返回响应
    return successResponse(recommendations);
  } catch (error) {
    return errorResponse(error.message, 400);
  }
});
```

## 依赖注入容器

**职责**: 管理服务实例的创建和生命周期

**设计模式**: Dependency Injection Container + Singleton

**核心功能**:
- 自动注册所有仓储和服务
- 管理依赖关系
- 提供类型安全的服务获取

**示例**:
```typescript
class Container {
  private static instance: Container;
  private services: Map<string, unknown> = new Map();

  private constructor(private readonly supabase: SupabaseClient) {
    this.registerRepositories();
    this.registerServices();
  }

  static getInstance(supabase: SupabaseClient): Container {
    if (!Container.instance) {
      Container.instance = new Container(supabase);
    }
    return Container.instance;
  }

  private registerRepositories(): void {
    this.services.set("IContentRepository", new SupabaseContentRepository(this.supabase));
    // ...
  }

  private registerServices(): void {
    const contentRepo = this.get<IContentRepository>("IContentRepository");
    this.services.set("ContentService", new ContentService(contentRepo));
    // ...
  }

  getContentService(): ContentService {
    return this.get<ContentService>("ContentService");
  }
}
```

## SOLID 原则应用

### 1. 单一职责原则 (SRP)

每个类只有一个改变的理由：

- `Content`: 只负责内容数据和业务规则
- `ContentService`: 只负责内容业务逻辑
- `SupabaseContentRepository`: 只负责 Supabase 数据访问
- `GetRecommendationsRequest`: 只负责请求数据验证

### 2. 开闭原则 (OCP)

对扩展开放，对修改关闭：

```typescript
// 添加新的数据源，不需要修改现有代码
class RedisContentRepository implements IContentRepository {
  // Redis 实现
}

// 在容器中注册新实现
this.services.set("IContentRepository", new RedisContentRepository(redis));
```

### 3. 里氏替换原则 (LSP)

子类可以替换父类：

```typescript
// 所有实现都可以替换接口
const repo: IContentRepository = new SupabaseContentRepository(supabase);
const repo: IContentRepository = new MongoContentRepository(mongo);
const repo: IContentRepository = new RedisContentRepository(redis);

// 服务层不需要知道具体实现
const service = new ContentService(repo);
```

### 4. 接口隔离原则 (ISP)

接口小而专注：

```typescript
// 不好的设计：一个大接口
interface IRepository {
  findById(id: string): Promise<Content | null>;
  findByScenario(scenario: Scenario): Promise<Content[]>;
  createFeedback(feedback: UserFeedback): Promise<void>;
  findRecommendations(scenario: string): Promise<Recommendation[]>;
}

// 好的设计：多个小接口
interface IContentRepository {
  findById(id: string): Promise<Content | null>;
  findByScenario(scenario: Scenario): Promise<Content[]>;
}

interface IFeedbackRepository {
  create(feedback: UserFeedback): Promise<UserFeedback>;
  findByContentId(contentId: string): Promise<UserFeedback[]>;
}

interface IRecommendationRepository {
  findByScenario(scenario: string): Promise<Recommendation[]>;
}
```

### 5. 依赖倒置原则 (DIP)

高层模块依赖抽象：

```typescript
// 不好的设计：依赖具体实现
class ContentService {
  constructor(private readonly supabaseRepo: SupabaseContentRepository) {}
}

// 好的设计：依赖抽象
class ContentService {
  constructor(private readonly contentRepository: IContentRepository) {}
}
```

## 数据流

```
┌─────────────┐
│   客户端     │
└──────┬──────┘
       │ HTTP Request
       ↓
┌─────────────────────────────────────┐
│  Edge Function (API层)               │
│  - 验证请求                          │
│  - 解析参数                          │
│  - 调用服务                          │
└──────┬──────────────────────────────┘
       │
       ↓
┌─────────────────────────────────────┐
│  Container (依赖注入容器)            │
│  - 创建服务实例                      │
│  - 管理依赖关系                      │
└──────┬──────────────────────────────┘
       │
       ↓
┌─────────────────────────────────────┐
│  Service Layer (服务层)              │
│  - 编排业务逻辑                      │
│  - 调用仓储                          │
└──────┬──────────────────────────────┘
       │
       ↓
┌─────────────────────────────────────┐
│  Repository Layer (仓储层)           │
│  - 查询数据库                        │
│  - 转换数据                          │
└──────┬──────────────────────────────┘
       │
       ↓
┌─────────────────────────────────────┐
│  Domain Layer (领域层)               │
│  - 创建实体                          │
│  - 应用业务规则                      │
└──────┬──────────────────────────────┘
       │
       ↓ 返回结果
┌─────────────┐
│   客户端     │
└─────────────┘
```

## 测试策略

### 1. 单元测试

测试领域模型和服务层：

```typescript
// 测试领域模型
Deno.test("Content.incrementViewCount should increase view count", () => {
  const content = new Content(/* ... */);
  const updated = content.incrementViewCount();
  assertEquals(updated.viewCount, content.viewCount + 1);
  assertEquals(content.viewCount, 100); // 原对象不变
});

// 测试服务层（使用 Mock Repository）
Deno.test("ContentService.getContentDetail should return content", async () => {
  const mockRepo = new MockContentRepository();
  const service = new ContentService(mockRepo);
  const content = await service.getContentDetail("test-id");
  assertExists(content);
});
```

### 2. 集成测试

测试仓储层和数据库交互：

```typescript
Deno.test("SupabaseContentRepository.findById should fetch from database", async () => {
  const supabase = createClient(/* ... */);
  const repo = new SupabaseContentRepository(supabase);
  const content = await repo.findById("real-id");
  assertExists(content);
});
```

### 3. E2E 测试

测试完整的 API 流程：

```typescript
Deno.test("GET /get-recommendations should return recommendations", async () => {
  const response = await fetch("http://localhost:54321/functions/v1/get-recommendations?scenario=coding");
  const data = await response.json();
  assertEquals(data.success, true);
  assertExists(data.data);
});
```

## 扩展性

### 1. 添加新的数据源

只需实现对应的 Repository 接口：

```typescript
class ElasticsearchContentRepository implements IContentRepository {
  async findById(id: string): Promise<Content | null> {
    // Elasticsearch 实现
  }
  
  async search(query: string): Promise<Content[]> {
    // 利用 Elasticsearch 的全文搜索能力
  }
}
```

### 2. 添加新的业务逻辑

在 Service 层添加新方法：

```typescript
class ContentService {
  async getRelatedContent(id: string): Promise<Content[]> {
    const content = await this.contentRepository.findById(id);
    if (!content) return [];
    
    // 基于场景和内容类型查找相关内容
    return await this.contentRepository.findByScenario(content.scenario);
  }
}
```

### 3. 添加新的 API 端点

创建新的 Edge Function：

```typescript
// functions/get-related-content/index.ts
serve(async (req) => {
  const container = Container.getInstance(supabase);
  const contentService = container.getContentService();
  const related = await contentService.getRelatedContent(id);
  return successResponse(related);
});
```

## 性能优化建议

1. **缓存层**: 在 Service 层添加 Redis 缓存
2. **批量查询**: Repository 支持批量操作
3. **数据库索引**: 在常用查询字段上建立索引
4. **连接池**: 复用数据库连接
5. **CDN**: 静态资源使用 CDN 加速

## 安全性考虑

1. **输入验证**: 使用 Zod 验证所有输入
2. **SQL 注入防护**: 使用参数化查询
3. **RLS 策略**: 数据库层面的权限控制
4. **Rate Limiting**: API 层面的限流
5. **CORS**: 配置正确的跨域策略

## 总结

本架构设计的核心优势：

1. **高内聚低耦合**: 每层职责清晰，依赖关系明确
2. **易于测试**: 通过接口和依赖注入，可以轻松编写单元测试
3. **易于扩展**: 符合开闭原则，添加新功能不需要修改现有代码
4. **易于维护**: 代码结构清晰，业务逻辑集中在服务层
5. **类型安全**: 使用 TypeScript 和 Zod 保证类型安全
