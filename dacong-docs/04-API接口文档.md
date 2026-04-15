# API 接口文档

## 1. 认证

所有需要认证的接口通过 Supabase Auth JWT：

```
Authorization: Bearer <supabase_jwt_token>
```

匿名请求仅可访问公开数据（模型列表、帖子流等）。

---

## 2. 模型相关

### 2.1 获取模型列表

```
GET /rest/v1/models
```

**查询参数：**

| 参数 | 类型 | 说明 |
|------|------|------|
| category | string | 筛选类别：llm/vlm/tts/embedding |
| vendor | string | 筛选厂商 |
| page | int | 页码，默认1 |
| per_page | int | 每页条数，默认20 |

**响应：**
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "GPT-4",
      "vendor": "OpenAI",
      "category": "llm",
      "description": "...",
      "rank_overall": 1,
      "score": 98.5
    }
  ],
  "total": 100,
  "page": 1,
  "per_page": 20
}
```

### 2.2 获取模型详情

```
GET /rest/v1/models?id=eq.{id}
```

### 2.3 获取榜单

```
GET /rest/v1/model_ranks
  ?select=*,models(*)
  &order=rank_overall.asc
  &limit=100
```

---

## 3. 帖子相关

### 3.1 获取帖子流

```
GET /rest/v1/posts
  ?select=*,profiles(username,avatar_url),topics(name)
  &order=created_at.desc
  &limit=20
```

### 3.2 发布帖子

```
POST /rest/v1/posts
```

**Body：**
```json
{
  "title": "标题",
  "content": "正文",
  "post_type": "text",
  "topic_id": "uuid (可选)"
}
```

**行为：**
1. 写入 posts 表，`moderation_status = 'pending'`
2. 触发器写入 moderation_queue
3. 返回 201，后端异步审核

### 3.3 点赞

```
POST /rest/v1/likes
```

**Body：**
```json
{
  "target_type": "post",
  "target_id": "uuid"
}
```

---

## 4. Realtime 订阅

### 4.1 帖子流实时更新

```javascript
const supabase = createClient(url, key)
supabase
  .channel('posts')
  .on('postgres_changes', { 
    event: 'INSERT', 
    schema: 'public', 
    table: 'posts',
    filter: 'moderation_status=eq.passed'
  }, handleNewPost)
  .subscribe()
```

### 4.2 私信实时

```javascript
supabase
  .channel('dm:user_123')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'messages',
    filter: 'receiver_id=eq.user_123'
  }, handleNewMessage)
  .subscribe()
```

---

## 5. Edge Functions

### 5.1 内容审核触发器

```
POST /functions/v1/moderation-trigger
```

**触发时机：** posts 表 AFTER INSERT

### 5.2 榜单权重计算

```
POST /functions/v1/rank-calc
```

**触发时机：** 每日定时（APScheduler）

### 5.3 推送触发

```
POST /functions/v1/push-trigger
```

**触发时机：** 新快讯写入后

---

## 6. 错误码

| 状态码 | 说明 |
|--------|------|
| 400 | 参数错误 |
| 401 | 未认证 |
| 403 | 无权限 |
| 404 | 资源不存在 |
| 422 | 业务校验失败（如内容违规） |
| 429 | 请求过于频繁 |
| 500 | 服务器错误 |
