# 输入验证指南

## 概述

本文档描述了 DaCong 项目中的输入验证系统，包括前端、后端和数据库层面的验证策略。

## 目录

- [验证原则](#验证原则)
- [后端验证](#后端验证)
- [前端验证](#前端验证)
- [数据库约束](#数据库约束)
- [安全最佳实践](#安全最佳实践)
- [常见问题](#常见问题)

---

## 验证原则

### 核心原则

1. **永远不要信任用户输入** - 所有输入都必须验证
2. **前后端都要验证** - 前端验证提升用户体验，后端验证确保安全
3. **使用白名单而非黑名单** - 明确允许什么，而不是禁止什么
4. **验证后再清理** - 先验证格式，再清理危险内容
5. **记录验证失败** - 记录到审计日志以便分析攻击模式

### 验证层次

```
┌─────────────────────────────────────┐
│  前端验证（用户体验）                │
│  - 实时反馈                          │
│  - 格式检查                          │
│  - 长度限制                          │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  后端验证（安全保障）                │
│  - Schema 验证                       │
│  - 业务规则验证                      │
│  - XSS/SQL 注入检查                  │
│  - 审计日志记录                      │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  数据库约束（最后防线）              │
│  - CHECK 约束                        │
│  - 外键约束                          │
│  - 唯一性约束                        │
└─────────────────────────────────────┘
```

---

## 后端验证

### 使用 Zod Schema

所有 API 端点都应使用 Zod Schema 进行验证。

#### 示例：用户注册

```typescript
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";
import { registerSchema } from "../_shared/schemas/auth_schemas.ts";
import { validateInput } from "../_shared/schemas/auth_schemas.ts";

// 验证请求体
const body = await getRequestBody(req);
const input = validateInput(registerSchema, body);

// input 现在是类型安全的
console.log(input.email); // string
console.log(input.password); // string
console.log(input.username); // string
```

### 可用的 Schema

#### 认证相关 (`auth_schemas.ts`)

- `registerSchema` - 用户注册
- `loginSchema` - 用户登录
- `changePasswordSchema` - 修改密码
- `resetPasswordRequestSchema` - 请求重置密码
- `resetPasswordConfirmSchema` - 确认重置密码
- `verifyEmailSchema` - 邮箱验证

#### 内容相关 (`content_schemas.ts`)

- `submitFeedbackSchema` - 提交反馈
- `searchContentSchema` - 搜索内容
- `getContentDetailSchema` - 获取内容详情
- `getRecommendationsSchema` - 获取推荐内容

#### 评论相关 (`comment_schemas.ts`)

- `submitCommentSchema` - 提交评论
- `likeCommentSchema` - 点赞评论
- `reportCommentSchema` - 举报评论
- `getCommentsSchema` - 获取评论列表

#### 用户相关 (`user_schemas.ts`)

- `updateProfileSchema` - 更新用户资料
- `trackEventSchema` - 追踪事件

#### 管理相关 (`admin_schemas.ts`)

- `reviewContentSchema` - 审核内容
- `editContentSchema` - 编辑内容
- `deleteContentSchema` - 删除内容
- `moderateCommentSchema` - 审核评论
- `manageUserSchema` - 用户管理

#### 查询相关 (`query_schemas.ts`)

- `paginationSchema` - 分页参数
- `sortSchema` - 排序参数
- `searchSchema` - 搜索参数
- `dateRangeSchema` - 日期范围
- `idListSchema` - ID 列表
- `uuidParamSchema` - UUID 参数
- `languageSchema` - 语言参数
- `fullQuerySchema` - 完整查询参数

### 验证中间件

使用验证中间件自动验证请求：

```typescript
import { validate } from "../_shared/middleware/validation.ts";
import { registerSchema } from "../_shared/schemas/auth_schemas.ts";

const validated = await validate({
  body: registerSchema,
})(req);

if (validated instanceof Response) {
  return validated; // 验证失败，返回错误响应
}

// 验证成功，使用验证后的数据
const { body } = validated;
console.log(body.email); // 类型安全
```

### 验证工具函数

位于 `_shared/utils/validation.ts`：

```typescript
import {
  isValidEmail,
  isValidUrl,
  isValidUuid,
  isValidSlug,
  containsXss,
  containsSqlInjection,
  isWhitelistedDomain,
  validatePasswordStrength,
} from "../_shared/utils/validation.ts";

// 邮箱验证
if (!isValidEmail(email)) {
  return errorResponse("Invalid email format", 400);
}

// URL 验证
if (!isValidUrl(url)) {
  return errorResponse("Invalid URL format", 400);
}

// XSS 检查
if (containsXss(input)) {
  return errorResponse("Input contains potentially dangerous content", 400);
}

// 密码强度验证
const strength = validatePasswordStrength(password);
if (!strength.valid) {
  return errorResponse(
    `Weak password: ${strength.feedback.join(", ")}`,
    400
  );
}
```

### 清理工具函数

位于 `_shared/utils/sanitize.ts`：

```typescript
import {
  sanitizeUserInput,
  sanitizeUrl,
  sanitizeEmail,
  sanitizeFilename,
  sanitizeMarkdown,
  sanitizeSearchQuery,
  sanitizeTag,
  sanitizeSlug,
} from "../_shared/utils/sanitize.ts";

// 清理用户输入
const cleanInput = sanitizeUserInput(userInput);

// 清理 URL
const cleanUrl = sanitizeUrl(url);

// 清理 Markdown
const cleanMarkdown = sanitizeMarkdown(markdown);

// 清理搜索查询
const cleanQuery = sanitizeSearchQuery(searchQuery);
```

---

## 前端验证

### Flutter 验证器

位于 `lib/core/validation/validators.dart`：

```dart
import 'package:dacong_client/core/validation/validators.dart';

// 邮箱验证
final emailError = Validators.email(emailController.text);
if (emailError != null) {
  // 显示错误
}

// 密码强度验证
final passwordError = Validators.passwordStrength(passwordController.text);

// 用户名验证
final usernameError = Validators.username(usernameController.text);

// 组合验证
final error = Validators.compose(value, [
  Validators.required,
  (v) => Validators.minLength(v, 3),
  (v) => Validators.maxLength(v, 30),
]);
```

### 表单验证器

位于 `lib/core/validation/form_validators.dart`：

```dart
import 'package:dacong_client/core/validation/form_validators.dart';

// 注册表单
final validators = FormValidators.registrationForm();
final emailError = validators['email']!(emailController.text);

// 内容创建表单
final validators = FormValidators.contentForm();
final titleError = validators['title']!(titleController.text);

// 评论表单
final validators = FormValidators.commentForm();
final contentError = validators['content']!(contentController.text);
```

### 验证文本框组件

位于 `lib/presentation/widgets/validated_text_field.dart`：

```dart
import 'package:dacong_client/presentation/widgets/validated_text_field.dart';
import 'package:dacong_client/core/validation/validators.dart';

ValidatedTextField(
  label: '邮箱',
  hint: '请输入邮箱地址',
  validator: Validators.email,
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icons.email,
  onChanged: (value) {
    // 处理输入变化
  },
)

// 带异步验证（如检查用户名唯一性）
ValidatedTextField(
  label: '用户名',
  validator: Validators.username,
  asyncValidator: (value) async {
    // 调用 API 检查用户名是否已存在
    final exists = await checkUsernameExists(value);
    return exists ? '用户名已被使用' : null;
  },
  debounceDelay: 500, // 防抖延迟
)
```

---

## 数据库约束

### 应用约束

运行迁移以应用数据库约束：

```bash
cd dacong-api
supabase db push
```

### 约束类型

#### 格式约束

```sql
-- 邮箱格式
ALTER TABLE users
ADD CONSTRAINT users_email_format
CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$');

-- 用户名格式
ALTER TABLE users
ADD CONSTRAINT users_username_format
CHECK (username ~* '^[a-zA-Z0-9_-]{3,30}$');
```

#### 长度约束

```sql
-- 标题长度
ALTER TABLE contents
ADD CONSTRAINT contents_title_length
CHECK (char_length(title) BETWEEN 1 AND 200);

-- 评论长度
ALTER TABLE comments
ADD CONSTRAINT comments_content_length
CHECK (char_length(content) BETWEEN 1 AND 1000);
```

#### 枚举约束

```sql
-- 内容状态
ALTER TABLE contents
ADD CONSTRAINT contents_status_check
CHECK (status IN ('draft', 'published', 'archived', 'pending', 'approved', 'rejected'));

-- 反馈类型
ALTER TABLE user_feedback
ADD CONSTRAINT user_feedback_type_check
CHECK (feedback_type IN ('helpful', 'not_helpful', 'report', 'suggestion'));
```

#### 范围约束

```sql
-- 评分范围
ALTER TABLE user_feedback
ADD CONSTRAINT user_feedback_rating_range
CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5));

-- 点赞数非负
ALTER TABLE comments
ADD CONSTRAINT comments_likes_count_positive
CHECK (likes_count >= 0);
```

---

## 安全最佳实践

### XSS 防护

1. **转义 HTML 输出**

```typescript
import { escapeHtml } from "../_shared/utils/sanitize.ts";

const safeOutput = escapeHtml(userInput);
```

2. **使用内容安全策略 (CSP)**

```typescript
// 在响应头中设置 CSP
headers.set("Content-Security-Policy", "default-src 'self'; script-src 'self'");
```

3. **清理 Markdown**

```typescript
import { sanitizeMarkdown } from "../_shared/utils/sanitize.ts";

const safeMarkdown = sanitizeMarkdown(userMarkdown);
```

### SQL 注入防护

1. **使用参数化查询**

```typescript
// ✅ 正确：使用参数化查询
const { data } = await supabase
  .from("users")
  .select("*")
  .eq("email", userEmail);

// ❌ 错误：字符串拼接
const query = `SELECT * FROM users WHERE email = '${userEmail}'`;
```

2. **验证标识符**

```typescript
import { isValidSqlIdentifier } from "../_shared/utils/sanitize.ts";

if (!isValidSqlIdentifier(tableName)) {
  return errorResponse("Invalid table name", 400);
}
```

### 文件上传验证

```typescript
import { validateFile } from "../_shared/middleware/validation.ts";

const fileResult = await validateFile(req, "avatar", {
  maxSizeInMB: 5,
  allowedTypes: ["image/jpeg", "image/png", "image/webp"],
  required: true,
});

if (fileResult instanceof Response) {
  return fileResult; // 验证失败
}

const file = fileResult; // File 对象
```

### 密码安全

1. **强密码要求**

- 至少 8 个字符
- 包含大写字母
- 包含小写字母
- 包含数字
- 建议包含特殊字符

2. **密码哈希**

```typescript
// Supabase Auth 自动处理密码哈希
const { data, error } = await supabase.auth.signUp({
  email,
  password, // 自动使用 bcrypt 哈希
});
```

---

## 常见问题

### Q: 前端验证是否足够？

**A:** 不够。前端验证可以被绕过，必须在后端再次验证。前端验证主要用于提升用户体验。

### Q: 如何处理验证错误？

**A:** 返回清晰的错误消息，包含字段名和具体错误原因：

```typescript
return errorResponse("Validation failed", 400, {
  errors: [
    { field: "email", message: "Invalid email format" },
    { field: "password", message: "Password must be at least 8 characters" },
  ],
});
```

### Q: 如何验证嵌套对象？

**A:** 使用 Zod 的嵌套 Schema：

```typescript
const schema = z.object({
  user: z.object({
    name: z.string(),
    email: z.string().email(),
  }),
  settings: z.object({
    theme: z.enum(["light", "dark"]),
    language: z.enum(["zh", "en"]),
  }),
});
```

### Q: 如何验证数组？

**A:** 使用 Zod 的数组验证：

```typescript
const schema = z.object({
  tags: z.array(z.string().min(1).max(30)).min(1).max(10),
  ids: z.array(z.string().uuid()).min(1).max(100),
});
```

### Q: 如何自定义验证规则？

**A:** 使用 Zod 的 `refine` 方法：

```typescript
const schema = z.object({
  password: z.string(),
  confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ["confirmPassword"],
});
```

### Q: 如何处理异步验证？

**A:** 在 Flutter 中使用 `asyncValidator`：

```dart
ValidatedTextField(
  asyncValidator: (value) async {
    final response = await api.checkUsername(value);
    return response.exists ? '用户名已存在' : null;
  },
)
```

在后端中直接在验证后执行异步检查：

```typescript
const input = validateInput(registerSchema, body);

// 异步检查用户名唯一性
const { data: existingUser } = await supabase
  .from("profiles")
  .select("username")
  .eq("username", input.username)
  .single();

if (existingUser) {
  return errorResponse("Username already taken", 400);
}
```

---

## 相关文档

- [API 验证规则参考](../api/VALIDATION_RULES.md)
- [表单验证指南](../development/FORM_VALIDATION.md)
- [安全指南](./SECURITY.md)
- [数据库设计](../database/SCHEMA.md)

---

## 更新日志

- **2026-04-19**: 初始版本，包含完整的验证系统文档
