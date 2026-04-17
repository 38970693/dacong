# 输入验证与安全防护文档

## 概述

本文档描述了 Dacong API 的输入验证和安全防护机制，包括 SQL 注入防护、XSS 防护、输入验证规范等。

## 目录

- [输入验证原则](#输入验证原则)
- [Zod Schema 定义规范](#zod-schema-定义规范)
- [验证中间件使用](#验证中间件使用)
- [XSS 防护](#xss-防护)
- [SQL 注入防护](#sql-注入防护)
- [安全测试](#安全测试)

---

## 输入验证原则

### 核心原则

1. **永远不信任用户输入** - 所有来自客户端的数据都必须验证
2. **白名单优于黑名单** - 定义允许的输入，而不是禁止的输入
3. **尽早验证** - 在业务逻辑之前进行验证
4. **清晰的错误消息** - 返回有意义的验证错误信息
5. **多层防御** - 验证、清理、转义多管齐下

### 验证层次

```
┌─────────────────────────────────┐
│  1. Schema 验证 (Zod)           │  ← 类型、格式、长度
├─────────────────────────────────┤
│  2. 业务逻辑验证                 │  ← 存在性、权限、状态
├─────────────────────────────────┤
│  3. 输出清理                     │  ← HTML 转义、敏感词过滤
└─────────────────────────────────┘
```

---

## Zod Schema 定义规范

### 基本结构

所有 Schema 定义在 `_shared/schemas/` 目录下，按功能模块分类：

```
_shared/schemas/
├── content_schemas.ts    # 内容相关
├── comment_schemas.ts    # 评论相关
├── user_schemas.ts       # 用户相关
└── admin_schemas.ts      # 管理员相关
```

### Schema 定义示例

```typescript
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

export const submitCommentSchema = z.object({
  content_id: z.string().uuid("Invalid content ID format"),
  parent_id: z.string().uuid("Invalid parent comment ID format").optional().nullable(),
  content: z.string()
    .min(1, "Comment cannot be empty")
    .max(1000, "Comment must not exceed 1000 characters")
    .transform((val) => val.trim()),
});

export type SubmitCommentInput = z.infer<typeof submitCommentSchema>;
```

### 常用验证规则

#### 字符串验证

```typescript
// 基本字符串
z.string().min(1).max(100)

// 邮箱
z.string().email("Invalid email format")

// URL
z.string().url("Invalid URL format")

// UUID
z.string().uuid("Invalid UUID format")

// 正则表达式
z.string().regex(/^[a-zA-Z0-9_-]+$/, "Invalid format")

// 转换（去除空白）
z.string().transform((val) => val.trim())
```

#### 数字验证

```typescript
// 整数
z.number().int().min(1).max(100)

// 浮点数
z.number().min(0).max(5)

// 可选数字
z.number().optional()
```

#### 枚举验证

```typescript
// 字符串枚举
z.enum(["like", "unlike"], {
  errorMap: () => ({ message: "Action must be 'like' or 'unlike'" }),
})

// 数组
z.array(z.string().uuid()).min(1).max(100)
```

---

## 验证中间件使用

### 验证请求体

```typescript
import { validateBody } from "../_shared/middleware/validation.ts";
import { submitCommentSchema } from "../_shared/schemas/comment_schemas.ts";

serve(async (req) => {
  // 验证输入
  const validation = await validateBody(req, submitCommentSchema);
  if (!validation.success) {
    return validation.response; // 返回 400 错误
  }

  const { content_id, content, parent_id } = validation.data;
  
  // 业务逻辑...
});
```

### 验证查询参数

```typescript
import { validateQuery } from "../_shared/middleware/validation.ts";
import { searchContentSchema } from "../_shared/schemas/content_schemas.ts";

serve(async (req) => {
  const validation = validateQuery(req, searchContentSchema);
  if (!validation.success) {
    return validation.response;
  }

  const { query, page, limit } = validation.data;
  
  // 业务逻辑...
});
```

### 验证路径参数

```typescript
import { validateParams } from "../_shared/middleware/validation.ts";

const validation = validateParams(
  { id: "550e8400-e29b-41d4-a716-446655440000" },
  z.object({ id: z.string().uuid() })
);
```

### 错误响应格式

验证失败时返回的错误格式：

```json
{
  "success": false,
  "error": "Validation failed",
  "details": [
    {
      "path": ["content"],
      "message": "Comment must not exceed 1000 characters"
    }
  ]
}
```

---

## XSS 防护

### 防护策略

1. **HTML 转义** - 转义所有特殊字符
2. **标签移除** - 移除 HTML 标签
3. **协议过滤** - 仅允许安全协议（http/https）
4. **事件处理器移除** - 移除 onclick 等事件

### 使用清理工具

```typescript
import { 
  sanitizeUserInput, 
  sanitizeComment,
  escapeHtml 
} from "../_shared/utils/sanitize.ts";

// 清理用户输入
const cleanInput = sanitizeUserInput(userInput);

// 清理评论（包含敏感词检测）
const { sanitized, needsModeration } = sanitizeComment(comment);

// HTML 转义
const escaped = escapeHtml("<script>alert('XSS')</script>");
// 结果: &lt;script&gt;alert(&#039;XSS&#039;)&lt;/script&gt;
```

### 清理函数说明

#### `escapeHtml(text: string): string`

转义 HTML 特殊字符：

- `&` → `&amp;`
- `<` → `&lt;`
- `>` → `&gt;`
- `"` → `&quot;`
- `'` → `&#039;`
- `/` → `&#x2F;`

#### `sanitizeUserInput(input: string): string`

全面清理用户输入：

1. 移除前后空白
2. 移除 HTML 标签
3. 移除 JavaScript 协议
4. 移除 data: 协议
5. 移除 vbscript: 协议
6. 移除事件处理器（onclick 等）
7. 规范化空白字符
8. HTML 转义

#### `sanitizeComment(content: string)`

清理评论内容并检测敏感词：

```typescript
const { sanitized, needsModeration } = sanitizeComment(comment);

if (needsModeration) {
  // 包含敏感词，需要审核
  moderationStatus = "pending";
} else {
  // 自动通过
  moderationStatus = "approved";
}
```

### 敏感词过滤

```typescript
import { 
  containsSensitiveWords, 
  filterSensitiveWords 
} from "../_shared/utils/sanitize.ts";

// 检查是否包含敏感词
if (containsSensitiveWords(text)) {
  // 需要审核
}

// 过滤敏感词（用 * 替换）
const filtered = filterSensitiveWords("这是垃圾内容");
// 结果: "这是**内容"
```

### CSP 头设置

在响应中设置 Content Security Policy：

```typescript
response.headers['Content-Security-Policy'] = "default-src 'self'";
response.headers['X-Content-Type-Options'] = 'nosniff';
response.headers['X-Frame-Options'] = 'DENY';
```

---

## SQL 注入防护

### 防护策略

1. **参数化查询** - 永远使用参数化查询，不拼接 SQL
2. **输入验证** - 验证所有输入的类型和格式
3. **最小权限** - 数据库用户仅有必要的权限
4. **ORM/查询构建器** - 使用 Supabase 客户端，避免原始 SQL

### Supabase 安全查询

✅ **正确做法**：使用 Supabase 客户端

```typescript
// 参数化查询 - 安全
const { data, error } = await supabase
  .from('comments')
  .select('*')
  .eq('content_id', contentId)  // 参数化
  .eq('user_id', userId);       // 参数化
```

❌ **错误做法**：拼接 SQL

```typescript
// SQL 拼接 - 危险！
const query = `SELECT * FROM comments WHERE content_id = '${contentId}'`;
```

### UUID 验证

所有 ID 必须验证为有效的 UUID：

```typescript
z.string().uuid("Invalid ID format")
```

这可以防止：
- SQL 注入尝试
- 路径遍历
- 无效的数据库查询

### 搜索查询安全

搜索查询需要清理和限制：

```typescript
import { sanitizeUserInput } from "../_shared/utils/sanitize.ts";

// 清理搜索查询
const sanitizedQuery = sanitizeUserInput(searchQuery);

// 使用 Supabase 的 ilike（参数化）
query = query.or(`title.ilike.%${sanitizedQuery}%,content.ilike.%${sanitizedQuery}%`);
```

### 标识符验证

如果必须使用动态表名或列名（不推荐），验证标识符：

```typescript
import { isValidSqlIdentifier } from "../_shared/utils/sanitize.ts";

if (!isValidSqlIdentifier(tableName)) {
  throw new Error("Invalid table name");
}
```

---

## 安全测试

### 运行测试

#### SQL 注入测试

```bash
cd supabase/functions/tests/security

# 设置环境变量
export SUPABASE_ANON_KEY="your-anon-key"
export API_BASE_URL="http://localhost:54321/functions/v1"

# 运行测试
chmod +x test_sql_injection.sh
./test_sql_injection.sh
```

#### XSS 测试

```bash
cd supabase/functions/tests/security

# 设置环境变量
export SUPABASE_ANON_KEY="your-anon-key"
export API_BASE_URL="http://localhost:54321/functions/v1"
export AUTH_TOKEN="your-auth-token"  # 可选

# 运行测试
chmod +x test_xss.sh
./test_xss.sh
```

### 测试覆盖

#### SQL 注入测试场景

1. UNION SELECT 注入
2. DROP TABLE 注入
3. 布尔盲注（OR 1=1）
4. 注释符注入（--）
5. 无效 UUID 格式
6. 超长输入

#### XSS 测试场景

1. 基本 `<script>` 标签
2. IMG onerror 注入
3. JavaScript 协议
4. 事件处理器（onclick）
5. SVG onload 注入
6. iframe 注入
7. data: 协议
8. vbscript: 协议
9. HTML 实体编码绕过
10. 大小写混淆

### 预期结果

所有测试应该返回：
- HTTP 400（验证失败）
- HTTP 401（未认证）
- 或者响应中恶意代码已被转义

---

## 最佳实践

### 开发清单

在实现新的 API 端点时，确保：

- [ ] 定义 Zod Schema
- [ ] 使用验证中间件
- [ ] 清理用户输入
- [ ] 使用参数化查询
- [ ] 验证 UUID 格式
- [ ] 设置安全响应头
- [ ] 编写安全测试

### 代码审查清单

审查代码时检查：

- [ ] 没有 SQL 拼接
- [ ] 没有 `eval()` 或 `Function()` 构造器
- [ ] 用户输入已验证
- [ ] 敏感数据已转义
- [ ] 错误消息不泄露敏感信息
- [ ] 日志不包含密码/token

### 常见陷阱

❌ **不要这样做**：

```typescript
// 1. 直接使用用户输入
const query = `SELECT * FROM users WHERE id = '${userId}'`;

// 2. 不验证输入
const { content } = await req.json();
await supabase.from('comments').insert({ content });

// 3. 信任客户端数据
const { isAdmin } = await req.json();
if (isAdmin) { /* 危险！*/ }
```

✅ **应该这样做**：

```typescript
// 1. 使用参数化查询
const { data } = await supabase
  .from('users')
  .select('*')
  .eq('id', userId);

// 2. 验证输入
const validation = await validateBody(req, schema);
if (!validation.success) return validation.response;

// 3. 服务端验证权限
const { data: { user } } = await supabase.auth.getUser();
const isAdmin = await checkAdminRole(user.id);
```

---

## 参考资源

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Zod Documentation](https://zod.dev/)
- [Supabase Security Best Practices](https://supabase.com/docs/guides/auth/security)
- [Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)

---

## 更新日志

- **2026-04-17**: 初始版本，包含输入验证、XSS 防护、SQL 注入防护
