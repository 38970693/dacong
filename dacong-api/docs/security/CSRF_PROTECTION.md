# CSRF 防护机制

## 概述

本文档描述了大聪项目中实现的 CSRF（跨站请求伪造）防护机制。

## CSRF 攻击原理

### 什么是 CSRF？

CSRF（Cross-Site Request Forgery，跨站请求伪造）是一种网络攻击方式，攻击者诱导用户在已登录的网站上执行非预期的操作。

### 攻击场景示例

1. 用户登录了 `https://dacong.com`，浏览器保存了认证 Cookie
2. 用户访问恶意网站 `https://evil.com`
3. 恶意网站包含如下代码：
   ```html
   <form action="https://dacong.com/api/submit-comment" method="POST">
     <input name="content" value="恶意评论" />
   </form>
   <script>document.forms[0].submit();</script>
   ```
4. 浏览器自动携带 Cookie 发送请求，服务端无法区分是否为用户真实意图

### 危害

- 未经授权的操作（发布内容、修改资料、转账等）
- 数据泄露
- 账户劫持

## 防护机制

### Double Submit Cookie 模式

我们采用 **Double Submit Cookie** 模式实现 CSRF 防护：

1. **Token 生成**：服务端生成加密安全的随机 Token
2. **Cookie 存储**：Token 存储在 HttpOnly Cookie 中
3. **Header 传递**：客户端在请求头中携带相同的 Token
4. **服务端验证**：验证 Cookie 和 Header 中的 Token 是否一致

### 为什么这样安全？

- **同源策略**：恶意网站无法读取其他域的 Cookie
- **无法伪造**：攻击者无法获取 Token 值，因此无法在请求头中设置
- **时间戳验证**：Token 包含时间戳，防止重放攻击

## 实现细节

### 后端实现

#### 1. CSRF 中间件 (`csrf.ts`)

```typescript
// 生成 Token
export function generateCsrfToken(): CsrfToken {
  const token = generateSecureToken(); // 32 字节随机数
  const timestamp = Date.now();
  return { token, timestamp };
}

// 验证 Token
export async function validateCsrfToken(req: Request): Promise<Response | null> {
  // 1. 从 Cookie 提取 Token
  const cookieToken = extractCsrfTokenFromCookie(req);
  
  // 2. 检查是否过期（1 小时）
  if (isTokenExpired(cookieToken.timestamp)) {
    return errorResponse('CSRF token expired', 403);
  }
  
  // 3. 从 Header 提取 Token
  const headerToken = extractCsrfTokenFromHeader(req);
  
  // 4. 验证一致性
  if (headerToken !== encodeToken(cookieToken)) {
    return errorResponse('CSRF token mismatch', 403);
  }
  
  return null; // 验证通过
}
```

#### 2. Token 格式

```
token:timestamp
```

示例：
```
a1b2c3d4e5f6...1234567890:1704067200000
```

#### 3. Cookie 属性

```typescript
Set-Cookie: csrf_token=<token>; HttpOnly; Secure; SameSite=Strict; Max-Age=3600; Path=/
```

- **HttpOnly**：防止 JavaScript 读取
- **Secure**：仅通过 HTTPS 传输（生产环境）
- **SameSite=Strict**：防止跨站请求携带
- **Max-Age=3600**：1 小时有效期

#### 4. 集成到 API

```typescript
import { csrfMiddleware } from '../_shared/middleware/csrf.ts';

serve(async (req) => {
  // CSRF 防护
  const csrfError = await csrfMiddleware(req);
  if (csrfError) return csrfError;
  
  // 业务逻辑
  // ...
});
```

#### 5. 受保护的 API

所有状态变更 API 都启用了 CSRF 防护：

- `submit-feedback` - 提交反馈
- `submit-comment` - 提交评论
- `like-comment` - 点赞评论
- `report-comment` - 举报评论
- `admin-user-management` - 用户管理（POST/DELETE）
- `admin-content-management` - 内容管理（POST/PUT/DELETE）
- `admin-comment-moderation` - 评论审核（POST）

**注意**：GET 请求不需要 CSRF Token。

### 前端实现

#### 1. CSRF 拦截器 (`csrf_interceptor.dart`)

```dart
class CsrfInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 只对状态变更方法添加 CSRF Token
    if (_isStateMutatingMethod(options.method)) {
      final token = await _getValidToken();
      if (token != null) {
        options.headers['x-csrf-token'] = token;
      }
    }
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 如果是 CSRF 错误，刷新 Token 并重试
    if (err.response?.statusCode == 403 && _isCsrfError(err.response?.data)) {
      await _refreshToken();
      // 重试请求
      // ...
    }
    handler.next(err);
  }
}
```

#### 2. Token 管理

- **存储**：使用 `SharedPreferences` 本地存储
- **过期检查**：每次请求前检查是否过期
- **自动刷新**：剩余时间 < 5 分钟时自动刷新
- **错误重试**：403 错误时自动刷新并重试

#### 3. 集成到 Dio

```dart
final dio = Dio();
dio.interceptors.add(CsrfInterceptor(
  baseUrl: apiBaseUrl,
  prefs: sharedPreferences,
));
```

## 使用指南

### 获取 CSRF Token

**API 端点**：`GET /get-csrf-token`

**响应**：
```json
{
  "token": "a1b2c3d4e5f6...1234567890:1704067200000",
  "expiresIn": 3600
}
```

**使用场景**：
- 应用启动时
- Token 过期后
- 登录后

### 发送受保护的请求

**请求头**：
```
x-csrf-token: <token>
Cookie: csrf_token=<token>
```

**示例**：
```bash
curl -X POST https://api.dacong.com/submit-comment \
  -H "Content-Type: application/json" \
  -H "x-csrf-token: a1b2c3d4e5f6...1234567890:1704067200000" \
  -H "Cookie: csrf_token=a1b2c3d4e5f6...1234567890:1704067200000" \
  -d '{"content_id":"123","content":"评论内容"}'
```

### 错误处理

#### 403 - CSRF token missing in cookie
```json
{
  "error": "CSRF token missing in cookie"
}
```
**解决方案**：调用 `/get-csrf-token` 获取新 Token

#### 403 - CSRF token expired
```json
{
  "error": "CSRF token expired"
}
```
**解决方案**：调用 `/get-csrf-token` 刷新 Token

#### 403 - CSRF token mismatch
```json
{
  "error": "CSRF token mismatch"
}
```
**解决方案**：检查 Cookie 和 Header 中的 Token 是否一致

## 安全测试

### 运行测试脚本

```bash
cd dacong-api/supabase/functions/tests/security
./test_csrf.sh
```

### 测试场景

1. ✅ 无 Token 请求被拒绝
2. ✅ 错误 Token 请求被拒绝
3. ✅ 过期 Token 请求被拒绝
4. ✅ 正确 Token 请求成功
5. ✅ Token 刷新正常
6. ✅ GET 请求不需要 CSRF Token

### 手动测试

#### 测试 1：获取 Token
```bash
curl -v http://localhost:54321/functions/v1/get-csrf-token
```

#### 测试 2：无 Token 请求（应失败）
```bash
curl -X POST http://localhost:54321/functions/v1/submit-feedback \
  -H "Content-Type: application/json" \
  -d '{"content_id":"test","is_helpful":true}'
```

#### 测试 3：有效 Token 请求（应成功）
```bash
TOKEN="<从测试1获取的token>"
curl -X POST http://localhost:54321/functions/v1/submit-feedback \
  -H "Content-Type: application/json" \
  -H "x-csrf-token: $TOKEN" \
  -H "Cookie: csrf_token=$TOKEN" \
  -d '{"content_id":"test","is_helpful":true}'
```

## 最佳实践

### 开发建议

1. **始终验证**：所有状态变更 API 必须启用 CSRF 防护
2. **及时刷新**：Token 即将过期时提前刷新
3. **错误处理**：优雅处理 CSRF 错误，自动重试
4. **日志记录**：记录 CSRF 验证失败的请求（可能是攻击）

### 安全建议

1. **HTTPS Only**：生产环境必须使用 HTTPS
2. **SameSite Cookie**：启用 SameSite=Strict
3. **Token 轮换**：定期轮换 Token
4. **监控告警**：监控 CSRF 验证失败率

### 性能优化

1. **缓存 Token**：客户端缓存 Token，减少请求
2. **提前刷新**：剩余时间 < 5 分钟时提前刷新
3. **批量请求**：多个请求共用一个 Token

## 常见问题

### Q1: 为什么 GET 请求不需要 CSRF Token？

**A**: GET 请求应该是幂等的，不应该修改服务器状态。CSRF 攻击的目标是执行状态变更操作，因此只需保护 POST/PUT/PATCH/DELETE 请求。

### Q2: Token 存储在哪里？

**A**: 
- **后端**：Token 存储在 HttpOnly Cookie 中，JavaScript 无法读取
- **前端**：Token 值存储在 SharedPreferences 中，用于设置请求头

### Q3: 如果 Token 过期了怎么办？

**A**: 前端拦截器会自动检测过期并刷新 Token，对用户透明。

### Q4: 是否需要为每个请求生成新 Token？

**A**: 不需要。Token 有效期为 1 小时，在有效期内可以复用。

### Q5: CSRF 防护是否影响性能？

**A**: 影响极小。Token 验证只是简单的字符串比较和时间戳检查，耗时 < 1ms。

## 参考资料

- [OWASP CSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)
- [Double Submit Cookie Pattern](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#double-submit-cookie)
- [SameSite Cookie Attribute](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite)

## 更新日志

- **2024-04-17**: 初始版本，实现 Double Submit Cookie 模式
