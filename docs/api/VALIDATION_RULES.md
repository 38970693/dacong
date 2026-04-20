# API 验证规则参考

## 概述

本文档详细列出了 DaCong API 中所有端点的验证规则。

## 目录

- [认证 API](#认证-api)
- [内容 API](#内容-api)
- [评论 API](#评论-api)
- [用户 API](#用户-api)
- [管理 API](#管理-api)
- [通用规则](#通用规则)

---

## 认证 API

### POST /auth-register

**用户注册**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| email | string | ✅ | 邮箱格式 |
| password | string | ✅ | 8-128字符，包含大小写字母和数字 |
| username | string | ✅ | 3-30字符，仅字母、数字、下划线、连字符 |

**示例请求：**

```json
{
  "email": "user@example.com",
  "password": "SecurePass123",
  "username": "john_doe"
}
```

**错误响应：**

```json
{
  "error": "Validation failed",
  "details": {
    "errors": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  }
}
```

---

### POST /auth-login

**用户登录**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| email | string | ✅ | 邮箱格式 |
| password | string | ✅ | 非空 |

---

### POST /auth-change-password

**修改密码**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| old_password | string | ✅ | 非空 |
| new_password | string | ✅ | 8-128字符，包含大小写字母和数字 |

---

### POST /auth-reset-password

**请求重置密码**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| email | string | ✅ | 邮箱格式 |

---

### POST /auth-verify-email

**验证邮箱**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| token | string | ✅ | 非空 |
| type | string | ❌ | 枚举：signup, email_change |

---

## 内容 API

### POST /submit-feedback

**提交反馈**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| content_id | string | ✅ | UUID 格式 |
| feedback_type | string | ✅ | 枚举：helpful, not_helpful |
| rating | number | ❌ | 整数，1-5 |
| comment | string | ❌ | 最多 500 字符 |

---

### GET /search-content

**搜索内容**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| query | string | ✅ | 1-100字符，自动 trim |
| scenario_id | string | ❌ | UUID 格式 |
| language | string | ❌ | 枚举：zh, en，默认 zh |
| page | number | ❌ | 正整数，默认 1 |
| limit | number | ❌ | 1-100，默认 20 |
| offset | number | ❌ | 非负整数，默认 0 |

---

### GET /get-content-detail

**获取内容详情**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| content_id | string | ✅ | UUID 格式 |
| language | string | ❌ | 枚举：zh, en，默认 zh |

---

### GET /get-recommendations

**获取推荐内容**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| content_id | string | ❌ | UUID 格式 |
| scenario_id | string | ❌ | UUID 格式 |
| language | string | ❌ | 枚举：zh, en，默认 zh |
| limit | number | ❌ | 1-50，默认 10 |

---

## 评论 API

### POST /submit-comment

**提交评论**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| content_id | string | ✅ | UUID 格式 |
| parent_id | string | ❌ | UUID 格式或 null |
| content | string | ✅ | 1-1000字符，自动 trim |

**示例请求：**

```json
{
  "content_id": "123e4567-e89b-12d3-a456-426614174000",
  "parent_id": null,
  "content": "这是一条评论"
}
```

---

### POST /like-comment

**点赞评论**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| comment_id | string | ✅ | UUID 格式 |
| action | string | ✅ | 枚举：like, unlike |

---

### POST /report-comment

**举报评论**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| comment_id | string | ✅ | UUID 格式 |
| reason | string | ✅ | 枚举：spam, harassment, hate_speech, violence, misinformation, other |
| description | string | ❌ | 最多 500 字符 |

---

### GET /get-comments

**获取评论列表**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| content_id | string | ✅ | UUID 格式 |
| parent_id | string | ❌ | UUID 格式或 null |
| page | number | ❌ | 正整数，默认 1 |
| limit | number | ❌ | 1-100，默认 20 |
| sort_by | string | ❌ | 枚举：created_at, likes_count，默认 created_at |
| sort_order | string | ❌ | 枚举：asc, desc，默认 desc |

---

## 用户 API

### PUT /update-profile

**更新用户资料**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| username | string | ❌ | 2-50字符，仅字母、数字、下划线、连字符 |
| avatar_url | string | ❌ | URL 格式 |
| bio | string | ❌ | 最多 200 字符 |

---

### POST /track-event

**追踪事件**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| event_type | string | ✅ | 枚举：page_view, content_view, search, feedback, comment, share, click |
| content_id | string | ❌ | UUID 格式 |
| metadata | object | ❌ | 任意键值对 |

---

## 管理 API

### POST /admin-content-management

**审核内容**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| content_ids | array | ✅ | UUID 数组，1-100 个 |
| action | string | ✅ | 枚举：approve, reject |
| reason | string | ❌ | 最多 200 字符 |

**示例请求：**

```json
{
  "content_ids": [
    "123e4567-e89b-12d3-a456-426614174000",
    "123e4567-e89b-12d3-a456-426614174001"
  ],
  "action": "approve",
  "reason": "内容符合规范"
}
```

---

### POST /admin-comment-moderation

**审核评论**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| comment_ids | array | ✅ | UUID 数组，1-100 个 |
| action | string | ✅ | 枚举：approve, reject, delete |
| reason | string | ❌ | 最多 200 字符 |

---

### POST /admin-user-management

**用户管理**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| user_id | string | ✅ | UUID 格式 |
| action | string | ✅ | 枚举：ban, unban, warn, set_role |
| reason | string | ❌ | 最多 200 字符 |
| role | string | ❌ | 枚举：user, moderator, admin |
| duration_days | number | ❌ | 整数，1-365 |

---

### POST /admin-batch-delete

**批量删除**

| 字段 | 类型 | 必填 | 验证规则 |
|------|------|------|----------|
| content_ids | array | ✅ | UUID 数组，1-100 个 |

---

### GET /admin-stats

**获取统计数据**

无需参数验证。

---

## 通用规则

### 分页参数

所有支持分页的端点都遵循以下规则：

| 字段 | 类型 | 默认值 | 验证规则 |
|------|------|--------|----------|
| page | number | 1 | 正整数，最小 1 |
| limit | number | 20 | 整数，1-100 |
| offset | number | 0 | 非负整数 |

---

### 排序参数

所有支持排序的端点都遵循以下规则：

| 字段 | 类型 | 默认值 | 验证规则 |
|------|------|--------|----------|
| sort_by | string | created_at | 字段名，1-50字符，仅字母、数字、下划线 |
| sort_order | string | desc | 枚举：asc, desc |

---

### 语言参数

所有支持多语言的端点都遵循以下规则：

| 字段 | 类型 | 默认值 | 验证规则 |
|------|------|--------|----------|
| language | string | zh | 枚举：zh, en |

---

### UUID 参数

所有 UUID 参数都必须符合以下格式：

```
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

示例：`123e4567-e89b-12d3-a456-426614174000`

---

### 日期时间参数

所有日期时间参数都必须符合 ISO 8601 格式：

```
YYYY-MM-DDTHH:mm:ss.sssZ
```

示例：`2026-04-19T12:00:00.000Z`

---

## 错误响应格式

### 验证失败

```json
{
  "error": "Validation failed",
  "details": {
    "errors": [
      {
        "field": "email",
        "message": "Invalid email format"
      },
      {
        "field": "password",
        "message": "Password must be at least 8 characters"
      }
    ]
  }
}
```

### 认证失败

```json
{
  "error": "Unauthorized",
  "message": "Authentication required"
}
```

### 权限不足

```json
{
  "error": "Forbidden",
  "message": "Insufficient permissions"
}
```

### 资源不存在

```json
{
  "error": "Not Found",
  "message": "Resource not found"
}
```

### 速率限制

```json
{
  "error": "Too Many Requests",
  "message": "Rate limit exceeded. Please try again later."
}
```

---

## 安全注意事项

### XSS 防护

所有文本输入都会自动进行 XSS 清理：

- HTML 标签会被转义或移除
- JavaScript 协议会被移除
- 事件处理器会被移除

### SQL 注入防护

所有数据库查询都使用参数化查询，无需担心 SQL 注入。

### CSRF 防护

所有修改数据的端点（POST、PUT、DELETE）都需要 CSRF Token。

在请求头中包含：

```
X-CSRF-Token: <token>
```

获取 Token：

```
GET /csrf-token
```

---

## 测试示例

### 使用 curl

```bash
# 注册用户
curl -X POST https://api.dacong.com/auth-register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123",
    "username": "john_doe"
  }'

# 搜索内容
curl -X GET "https://api.dacong.com/search-content?query=test&page=1&limit=20"

# 提交评论（需要认证）
curl -X POST https://api.dacong.com/submit-comment \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -H "X-CSRF-Token: <csrf-token>" \
  -d '{
    "content_id": "123e4567-e89b-12d3-a456-426614174000",
    "content": "这是一条评论"
  }'
```

---

## 相关文档

- [输入验证指南](../security/INPUT_VALIDATION.md)
- [API 认证](./AUTHENTICATION.md)
- [错误处理](./ERROR_HANDLING.md)

---

## 更新日志

- **2026-04-19**: 初始版本，包含所有 API 端点的验证规则
