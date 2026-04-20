# 开发模式配置指南

## 概述

开发模式配置系统允许你在开发阶段快速切换各种安全验证开关，专注于功能实现。生产环境会自动启用所有验证。

## 配置文件

配置通过环境变量控制，在 `.env` 文件中设置：

```bash
# 环境设置
ENVIRONMENT=development  # development 或 production

# 开发模式开关（仅在 ENVIRONMENT=development 时生效）
DEV_ENABLE_CSRF=false                      # CSRF 防护
DEV_ENABLE_AUTH=false                      # 认证验证
DEV_ENABLE_INPUT_VALIDATION=false          # 输入验证
DEV_ENABLE_SQL_INJECTION_PROTECTION=false  # SQL 注入防护
DEV_ENABLE_XSS_PROTECTION=false            # XSS 防护
DEV_ENABLE_RATE_LIMIT=false                # 速率限制
```

## 使用场景

### 场景 1: 快速开发新功能（全部禁用）

```bash
ENVIRONMENT=development
DEV_ENABLE_CSRF=false
DEV_ENABLE_AUTH=false
DEV_ENABLE_INPUT_VALIDATION=false
DEV_ENABLE_SQL_INJECTION_PROTECTION=false
DEV_ENABLE_XSS_PROTECTION=false
DEV_ENABLE_RATE_LIMIT=false
```

**适用于：**
- 快速原型开发
- 功能验证
- UI/UX 调试

### 场景 2: 逐步启用验证

```bash
ENVIRONMENT=development
DEV_ENABLE_CSRF=false
DEV_ENABLE_AUTH=true          # 先启用认证
DEV_ENABLE_INPUT_VALIDATION=true  # 再启用输入验证
DEV_ENABLE_SQL_INJECTION_PROTECTION=false
DEV_ENABLE_XSS_PROTECTION=false
DEV_ENABLE_RATE_LIMIT=false
```

**适用于：**
- 功能基本完成
- 开始补全安全机制
- 逐步测试各项验证

### 场景 3: 生产环境（全部启用）

```bash
ENVIRONMENT=production
# 生产环境会自动忽略所有 DEV_ENABLE_* 配置
# 强制启用所有安全验证
```

## 各验证项说明

### 1. CSRF 防护 (`DEV_ENABLE_CSRF`)

**作用：** 防止跨站请求伪造攻击

**禁用时：**
- 不需要在请求中携带 CSRF Token
- POST/PUT/PATCH/DELETE 请求不会被拦截

**启用时：**
- 需要先获取 CSRF Token
- 请求时需要在 Header 中携带 Token

### 2. 认证验证 (`DEV_ENABLE_AUTH`)

**作用：** 验证用户身份

**禁用时：**
- 返回模拟用户（id: 'dev-user-id', role: 'admin'）
- 不需要登录即可访问受保护的接口

**启用时：**
- 需要在 Authorization Header 中携带有效的 JWT Token
- 未登录用户会收到 401 错误

### 3. 输入验证 (`DEV_ENABLE_INPUT_VALIDATION`)

**作用：** 使用 Zod Schema 验证请求参数

**禁用时：**
- 跳过 Schema 验证
- 接受任意格式的输入

**启用时：**
- 严格验证请求参数格式
- 不符合 Schema 的请求会被拒绝

### 4. SQL 注入防护 (`DEV_ENABLE_SQL_INJECTION_PROTECTION`)

**作用：** 检测并阻止 SQL 注入攻击

**禁用时：**
- 不检查输入中的 SQL 关键字
- 允许包含 SQL 语句的输入

**启用时：**
- 检测输入中的危险 SQL 模式
- 拒绝包含 SQL 注入特征的请求

### 5. XSS 防护 (`DEV_ENABLE_XSS_PROTECTION`)

**作用：** 防止跨站脚本攻击

**禁用时：**
- 不检查输入中的脚本标签
- 允许包含 HTML/JavaScript 的输入

**启用时：**
- 检测输入中的危险脚本模式
- 拒绝包含 XSS 特征的请求

### 6. 速率限制 (`DEV_ENABLE_RATE_LIMIT`)

**作用：** 限制请求频率，防止滥用

**禁用时：**
- 不限制请求频率
- 可以快速测试

**启用时：**
- 限制每个 IP 的请求频率
- 超过限制会收到 429 错误

## 代码示例

### 在 Edge Function 中使用

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import { csrfMiddleware } from '../_shared/middleware/csrf.ts';
import { authMiddleware } from '../_shared/middleware/auth.ts';
import { printDevModeConfig } from '../_shared/config/dev-mode.ts';

serve(async (req) => {
  // 打印开发模式配置（仅开发环境）
  printDevModeConfig();

  // CSRF 验证（开发模式可禁用）
  const csrfError = await csrfMiddleware(req);
  if (csrfError) return csrfError;

  // 认证验证（开发模式可禁用）
  const supabase = createClient(/* ... */);
  const authResult = await authMiddleware(req, supabase);
  if (authResult instanceof Response) return authResult;

  const { user } = authResult;

  // 业务逻辑
  return new Response(JSON.stringify({ message: 'Success', user }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
```

### 查看当前配置

启动服务时会自动打印配置：

```
🔧 Development Mode Configuration:
  CSRF Protection: ❌
  Authentication: ❌
  Input Validation: ❌
  SQL Injection Protection: ❌
  XSS Protection: ❌
  Rate Limiting: ❌
```

## 开发流程建议

### 阶段 1: 快速开发（全部禁用）

```bash
# 专注于功能实现，不被验证打断
DEV_ENABLE_CSRF=false
DEV_ENABLE_AUTH=false
DEV_ENABLE_INPUT_VALIDATION=false
DEV_ENABLE_SQL_INJECTION_PROTECTION=false
DEV_ENABLE_XSS_PROTECTION=false
DEV_ENABLE_RATE_LIMIT=false
```

### 阶段 2: 功能完成后逐步启用

```bash
# 先启用认证和输入验证
DEV_ENABLE_AUTH=true
DEV_ENABLE_INPUT_VALIDATION=true
```

### 阶段 3: 补全安全机制

```bash
# 启用所有验证
DEV_ENABLE_CSRF=true
DEV_ENABLE_AUTH=true
DEV_ENABLE_INPUT_VALIDATION=true
DEV_ENABLE_SQL_INJECTION_PROTECTION=true
DEV_ENABLE_XSS_PROTECTION=true
DEV_ENABLE_RATE_LIMIT=true
```

### 阶段 4: 部署到生产

```bash
# 切换到生产环境，自动启用所有验证
ENVIRONMENT=production
```

## 注意事项

1. **生产环境强制启用所有验证**
   - `ENVIRONMENT=production` 时，所有 `DEV_ENABLE_*` 配置会被忽略
   - 确保生产环境的安全性

2. **不要在生产环境禁用验证**
   - 开发模式配置仅用于开发阶段
   - 生产环境必须启用所有安全验证

3. **逐步启用验证**
   - 建议在功能完成后逐步启用验证
   - 避免一次性启用所有验证导致大量错误

4. **测试覆盖**
   - 在启用验证前，确保有足够的测试覆盖
   - 验证启用后可能会暴露之前未发现的问题

## 文件结构

```
dacong-api/supabase/functions/
├── _shared/
│   ├── config/
│   │   └── dev-mode.ts          # 开发模式配置
│   ├── middleware/
│   │   ├── csrf.ts              # CSRF 中间件（支持开发模式）
│   │   └── auth.ts              # 认证中间件（支持开发模式）
│   └── utils/
│       └── validation.ts        # 验证工具（支持开发模式）
└── .env                         # 环境变量配置
```

## 相关文件

- [dev-mode.ts](../supabase/functions/_shared/config/dev-mode.ts) - 开发模式配置
- [csrf.ts](../supabase/functions/_shared/middleware/csrf.ts) - CSRF 中间件
- [auth.ts](../supabase/functions/_shared/middleware/auth.ts) - 认证中间件
- [validation.ts](../supabase/functions/_shared/utils/validation.ts) - 验证工具
- [.env.example](../.env.example) - 环境变量示例
