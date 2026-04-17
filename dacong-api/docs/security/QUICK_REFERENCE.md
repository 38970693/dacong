# 输入验证快速参考

## 快速开始

### 1. 创建 Schema

```typescript
// _shared/schemas/my_schemas.ts
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

export const mySchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(1).max(100),
  email: z.string().email(),
});

export type MyInput = z.infer<typeof mySchema>;
```

### 2. 在 API 中使用

```typescript
import { validateBody } from "../_shared/middleware/validation.ts";
import { mySchema } from "../_shared/schemas/my_schemas.ts";
import { sanitizeUserInput } from "../_shared/utils/sanitize.ts";

serve(async (req) => {
  // 验证输入
  const validation = await validateBody(req, mySchema);
  if (!validation.success) {
    return validation.response;
  }

  const { id, name, email } = validation.data;
  
  // 清理文本输入
  const cleanName = sanitizeUserInput(name);
  
  // 业务逻辑...
});
```

## 常用验证规则

### 字符串

```typescript
z.string()                              // 基本字符串
  .min(1, "不能为空")                   // 最小长度
  .max(100, "不能超过100字符")          // 最大长度
  .email("无效的邮箱格式")              // 邮箱
  .url("无效的URL格式")                 // URL
  .uuid("无效的UUID格式")               // UUID
  .regex(/^[a-z]+$/, "仅允许小写字母")  // 正则
  .transform(val => val.trim())         // 转换
  .optional()                           // 可选
  .nullable()                           // 可为null
```

### 数字

```typescript
z.number()                              // 基本数字
  .int("必须是整数")                    // 整数
  .min(1, "最小值为1")                  // 最小值
  .max(100, "最大值为100")              // 最大值
  .positive("必须为正数")               // 正数
  .nonnegative("不能为负数")            // 非负数
```

### 枚举

```typescript
z.enum(["option1", "option2"], {
  errorMap: () => ({ message: "无效的选项" })
})
```

### 数组

```typescript
z.array(z.string().uuid())              // UUID 数组
  .min(1, "至少需要一个元素")           // 最小长度
  .max(100, "最多100个元素")            // 最大长度
```

### 对象

```typescript
z.object({
  field1: z.string(),
  field2: z.number().optional(),
})
```

## 清理函数

### HTML 转义

```typescript
import { escapeHtml } from "../_shared/utils/sanitize.ts";

const safe = escapeHtml("<script>alert('XSS')</script>");
// 结果: &lt;script&gt;alert(&#039;XSS&#039;)&lt;/script&gt;
```

### 用户输入清理

```typescript
import { sanitizeUserInput } from "../_shared/utils/sanitize.ts";

const clean = sanitizeUserInput(userInput);
// 移除 HTML 标签、危险协议、事件处理器
```

### 评论清理

```typescript
import { sanitizeComment } from "../_shared/utils/sanitize.ts";

const { sanitized, needsModeration } = sanitizeComment(comment);

if (needsModeration) {
  // 包含敏感词，需要审核
}
```

### URL 清理

```typescript
import { sanitizeUrl } from "../_shared/utils/sanitize.ts";

const safeUrl = sanitizeUrl(userUrl);
// 仅允许 http/https/mailto/tel 协议
```

## 验证中间件

### 验证请求体 (POST/PUT)

```typescript
import { validateBody } from "../_shared/middleware/validation.ts";

const validation = await validateBody(req, schema);
if (!validation.success) {
  return validation.response; // 返回 400 错误
}

const data = validation.data;
```

### 验证查询参数 (GET)

```typescript
import { validateQuery } from "../_shared/middleware/validation.ts";

const validation = validateQuery(req, schema);
if (!validation.success) {
  return validation.response;
}

const { page, limit } = validation.data;
```

## 安全检查清单

在实现新 API 时：

- [ ] 定义 Zod Schema
- [ ] 使用验证中间件
- [ ] 清理用户输入
- [ ] 验证 UUID 格式
- [ ] 使用参数化查询（Supabase 客户端）
- [ ] 不拼接 SQL
- [ ] 不使用 eval()
- [ ] 设置安全响应头
- [ ] 编写安全测试

## 常见错误

### ❌ 不要这样做

```typescript
// 1. 不验证输入
const { id } = await req.json();
await supabase.from('table').select().eq('id', id);

// 2. SQL 拼接
const query = `SELECT * FROM table WHERE id = '${id}'`;

// 3. 不清理 HTML
return new Response(userInput); // XSS 风险

// 4. 信任客户端
const { isAdmin } = await req.json();
if (isAdmin) { /* 危险！*/ }
```

### ✅ 应该这样做

```typescript
// 1. 验证输入
const validation = await validateBody(req, schema);
if (!validation.success) return validation.response;

// 2. 参数化查询
await supabase.from('table').select().eq('id', validation.data.id);

// 3. 清理 HTML
const clean = sanitizeUserInput(userInput);

// 4. 服务端验证
const { data: { user } } = await supabase.auth.getUser();
const isAdmin = await checkAdminRole(user.id);
```

## 运行安全测试

```bash
cd supabase/functions/tests/security

# 设置环境变量
export SUPABASE_ANON_KEY="your-key"

# 运行所有测试
./run_all_tests.sh

# 或单独运行
./test_sql_injection.sh
./test_xss.sh
```

## 更多信息

详细文档：[docs/security/INPUT_VALIDATION.md](../../docs/security/INPUT_VALIDATION.md)
