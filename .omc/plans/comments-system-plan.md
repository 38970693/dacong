# 评论系统详细实现计划 (v2.1 Sprint 1)

**创建日期:** 2026-05-09
**模块:** 评论系统 + 点赞功能 (P0)
**目标:** 为 dacong-console 提供 REST API，为 dacong-client 提供后端支持

---

## RALPLAN-DR 结构摘要

### 指导原则 (Principles)

| # | 原则 | 说明 |
|---|------|------|
| P1 | **API 优先** | 先实现 Next.js REST API，Flutter 客户端通过 API 调用而非直接 Supabase |
| P2 | **向后兼容** | Flutter 的 Edge Functions 保持可用，新增 REST API 作为主接口 |
| P3 | **数据一致性** | comments 表使用统一结构，target_type 支持 post/review |
| P4 | **性能优先** | 使用 Supabase 连接池，避免每次请求创建新客户端 |
| P5 | **安全性** | 所有写入操作需要认证，读取操作支持公开访问 |

### 核心决策驱动 (Decision Drivers)

| 优先级 | 驱动因素 | 权重理由 |
|--------|----------|----------|
| D1 | **API 架构选择** - REST API vs GraphQL vs Edge Functions | REST API 最简单，与现有 tags/models/reviews API 风格一致 |
| D2 | **嵌套评论实现** - parent_id 自引用 vs 扁平结构 + depth 字段 | parent_id 自引用更灵活，支持无限层级嵌套 |
| D3 | **点赞实现** - likes 表独立 vs 在 comments/posts 表中增加 like_count | likes 表独立更清晰，支持用户维度的点赞状态查询 |

### 审查方案对比 (Options)

#### 方案 A: REST API + Supabase 直接连接 (推荐)

**思路:** 在 dacong-console/src/app/api/comments/route.ts 实现 REST API，使用环境变量中的 Supabase 连接。

| 优势 | 劣势 |
|------|------|
| 与现有 API 风格一致 | 需要管理 Supabase 服务角色密钥 |
| 支持 Vercel Edge Runtime | 需处理连接池管理 |
| 简单直接，易于调试 | - |

#### 方案 B: Supabase Edge Functions

**思路:** 使用 Edge Functions 包装 Supabase 操作。

| 优势 | 劣势 |
|------|------|
| 更安全（密钥不在客户端暴露） | 部署复杂度增加 |
| 可以在边缘执行 | 与现有 API 风格不一致 |

> **决策:** 采用方案 A - REST API + Supabase 直接连接
> **理由:** 与现有 dacong-console/src/app/api/*.ts 保持一致，减少技术栈复杂度

---

## ADR (Architecture Decision Record)

| 字段 | 内容 |
|------|------|
| **Decision** | 采用 REST API + Supabase 直接连接 |
| **Drivers** | 与现有 API 风格一致，简化部署，减少边缘函数数量 |
| **Alternatives considered** | 方案 B (Edge Functions) - 优势是更安全，但增加复杂度 |
| **Why chosen** | 现有项目使用 REST API 模式，继续保持一致性 |
| **Consequences** | 需要确保服务角色密钥安全存储在环境变量中 |
| **Follow-ups** | (1) 验证 API 响应格式与 Flutter 期望一致；(2) 考虑添加认证中间件 |

---

## 需求摘要

### 功能点

1. **评论 CRUD API**
   - GET /api/comments - 获取评论列表（支持分页、排序、嵌套）
   - POST /api/comments - 创建评论
   - DELETE /api/comments/[id] - 删除评论

2. **点赞功能**
   - POST /api/comments/[id]/like - 点赞评论
   - DELETE /api/comments/[id]/like - 取消点赞

3. **Flutter 客户端集成**
   - 更新 comment_remote_data_source.dart 使用 REST API
   - 可选：保持 Edge Functions 作为备用

### 用户故事

- **US1:** 作为访客，我可以查看帖子的评论列表
- **US2:** 作为登录用户，我可以发表、回复、删除自己的评论
- **US3:** 作为登录用户，我可以点赞/取消点赞评论
- **US4:** 作为用户，我可以看到评论的嵌套回复

---

## 数据库表结构

### 现有 comments 表

```sql
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  target_type TEXT NOT NULL CHECK (target_type IN ('post', 'review')),
  target_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  content TEXT NOT NULL,
  parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  likes INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_comments_target ON comments(target_type, target_id);
CREATE INDEX idx_comments_parent ON comments(parent_id);
CREATE INDEX idx_comments_user ON comments(user_id);
```

### 现有 likes 表

```sql
CREATE TABLE likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  target_type TEXT NOT NULL CHECK (target_type IN ('post', 'review', 'comment', 'model')),
  target_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, target_type, target_id)
);

CREATE INDEX idx_likes_target ON likes(target_type, target_id);
CREATE INDEX idx_likes_user ON likes(user_id);
```

---

## API 规范

### 1. GET /api/comments

获取评论列表

**查询参数:**
- `target_type`: 'post' | 'review' (必填)
- `target_id`: string (必填)
- `page`: number (默认 1)
- `limit`: number (默认 20, 最大 100)
- `sort`: 'latest' | 'popular' (默认 'latest')

**响应:**
```typescript
{
  success: true,
  data: {
    comments: (Comment & { user: { id, username, avatar }, replies?: Comment[] })[],
    total: number,
    page: number,
    limit: number,
    hasMore: boolean
  }
}
```

### 2. POST /api/comments

创建评论

**请求体:**
```typescript
{
  target_type: 'post' | 'review',
  target_id: string,
  content: string,
  parent_id?: string  // 可选，用于回复
}
```

**响应:**
```typescript
{
  success: true,
  data: Comment
}
```

### 3. DELETE /api/comments/[id]

删除评论（仅评论作者可删除）

**响应:**
```typescript
{
  success: true,
  data: { message: 'Comment deleted' }
}
```

### 4. POST /api/comments/[id]/like

点赞评论

**响应:**
```typescript
{
  success: true,
  data: { likes: number }
}
```

### 5. DELETE /api/comments/[id]/like

取消点赞

**响应:**
```typescript
{
  success: true,
  data: { likes: number }
}
```

---

## 实现步骤

### Phase 1: 数据库准备 (可选)

- [ ] 验证 comments 表结构与代码一致
- [ ] 验证 likes 表结构与代码一致
- [ ] 添加 comments_count 到 posts 表（如果不存在）

### Phase 2: REST API 实现

#### Step 1: 创建评论 API 路由

**文件:** `dacong-console/src/app/api/comments/route.ts`

- [ ] GET /api/comments - 获取评论列表（支持嵌套回复）
- [ ] POST /api/comments - 创建评论
- [ ] 输入验证 (target_type, target_id, content)
- [ ] 返回格式遵循 ApiResponse<T> 接口

#### Step 2: 创建评论详情/删除 API 路由

**文件:** `dacong-console/src/app/api/comments/[id]/route.ts`

- [ ] GET /api/comments/[id] - 获取单条评论
- [ ] DELETE /api/comments/[id] - 删除评论（需要认证）

#### Step 3: 创建点赞 API 路由

**文件:** `dacong-console/src/app/api/comments/[id]/like/route.ts`

- [ ] POST /api/comments/[id]/like - 添加点赞
- [ ] DELETE /api/comments/[id]/like - 移除点赞
- [ ] 使用 upsert 防止重复点赞

### Phase 3: Flutter 客户端更新

#### Step 4: 更新 CommentRemoteDataSource

**文件:** `dacong-client/lib/data/datasources/comment_remote_data_source.dart`

- [ ] 修改为使用 REST API (http package)
- [ ] 保持与现有 BLoC 的兼容性
- [ ] 添加错误处理

#### Step 5: 更新 Comment 模型

**文件:** `dacong-client/lib/domain/entities/comment.dart`

- [ ] 添加 user_email, user, replies 字段（如果需要）
- [ ] 确认与 API 响应格式匹配

### Phase 4: 集成与测试

- [ ] 测试 GET /api/comments 返回正确数据
- [ ] 测试 POST /api/comments 创建评论
- [ ] 测试嵌套评论（parent_id）
- [ ] 测试点赞/取消点赞
- [ ] 验证 Flutter 客户端与 API 集成正常

---

## 验收标准 (Acceptance Criteria)

| # | 标准 | 验证方法 |
|---|------|----------|
| AC1 | GET /api/comments 返回正确格式的评论列表 | curl 测试 |
| AC2 | POST /api/comments 成功创建评论 | 单元测试 |
| AC3 | 嵌套评论（parent_id）正确返回 | 集成测试 |
| AC4 | 点赞 API 正确更新 likes 计数 | API 测试 |
| AC5 | Flutter 客户端评论加载正常 | E2E 测试 |
| AC6 | API 响应时间 < 500ms | 性能测试 |
| AC7 | 所有 API 返回一致的 { success, data, error } 格式 | 代码审查 |
| AC8 | 输入验证完整（content 非空，长度限制） | 边界测试 |
| AC9 | 删除操作只允许评论作者 | 安全测试 |

---

## 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| Supabase 连接池耗尽 | API 请求失败 | 使用环境变量缓存连接，复用 supabase 客户端 |
| 嵌套评论查询性能 | 大量评论时响应慢 | 添加数据库索引，限制嵌套深度 |
| 用户认证缺失 | 未登录用户可发表评论 | 添加 auth 验证（后续迭代） |

---

## 验证步骤

1. **本地验证:**
   ```bash
   curl http://localhost:3000/api/comments?target_type=post&target_id=test123
   ```

2. **创建评论:**
   ```bash
   curl -X POST http://localhost:3000/api/comments \
     -H "Content-Type: application/json" \
     -d '{"target_type":"post","target_id":"test123","content":"Test comment"}'
   ```

3. **点赞测试:**
   ```bash
   curl -X POST http://localhost:3000/api/comments/{id}/like
   ```

---

## 后续迭代 (v2.1 Sprint 2+)

- 添加评论举报功能
- 添加评论编辑功能
- 添加评论通知
- 添加认证中间件

---

*Plan generated by planner agent on 2026/05/09*