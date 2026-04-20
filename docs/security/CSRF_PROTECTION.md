# CSRF Protection Implementation Guide

## Overview

This document describes the complete CSRF (Cross-Site Request Forgery) protection system implemented in the DaCong project. The system uses a hybrid approach combining Double Submit Cookie pattern with database-backed token storage for enhanced security.

## Architecture

### Components

1. **Backend (Supabase Edge Functions)**
   - CSRF middleware (`_shared/middleware/csrf.ts`)
   - CSRF token endpoint (`csrf-token/index.ts`)
   - Database storage (`csrf_tokens` table)

2. **Flutter Client**
   - CSRF service (`lib/core/security/csrf_service.dart`)
   - CSRF interceptor (`lib/core/security/csrf_interceptor.dart`)
   - API client integration

3. **Admin Dashboard**
   - CSRF service (`lib/services/csrf_service.dart`)
   - Admin API service integration

## Security Features

### Token Generation
- **Cryptographically secure random generation**: Uses `crypto.getRandomValues()` for 256-bit tokens
- **Timestamp-based expiry**: Tokens expire after 1 hour
- **User session binding**: Tokens are tied to specific user sessions

### Token Validation
- **Double Submit Cookie**: Token must match in both Cookie and Header
- **Database verification**: Token existence and validity checked in database
- **Constant-time comparison**: Prevents timing attacks
- **Expiry checking**: Automatic rejection of expired tokens

### Storage Security
- **HttpOnly cookies**: Prevents JavaScript access to cookie tokens
- **Secure flag**: Enforces HTTPS in production
- **SameSite=Strict**: Prevents cross-site cookie transmission
- **Database persistence**: Enables server-side token revocation

## Implementation Details

### Backend Integration

#### 1. Database Schema

```sql
CREATE TABLE csrf_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ,
  ip_address TEXT,
  user_agent TEXT
);
```

#### 2. Middleware Usage

**For authenticated endpoints:**

```typescript
import { csrfMiddleware } from "../_shared/middleware/csrf.ts";
import { requireAdmin } from "../_shared/middleware/admin.ts";

serve(async (req) => {
  const { user, supabase } = await requireAdmin(req);
  
  // CSRF validation with user verification
  const csrfError = await csrfMiddleware(req, supabase, user.id);
  if (csrfError) return csrfError;
  
  // Business logic
});
```

**For public endpoints (login, register):**

```typescript
import { csrfMiddleware } from "../_shared/middleware/csrf.ts";

serve(async (req) => {
  // CSRF validation without user verification
  const csrfError = await csrfMiddleware(req);
  if (csrfError) return csrfError;
  
  // Business logic
});
```

#### 3. Protected Endpoints

All state-changing operations (POST/PUT/PATCH/DELETE) are protected:

**Authentication:**
- `auth-register`
- `auth-login`
- `auth-logout`
- `auth-change-password`
- `auth-reset-password`

**Content Management:**
- `admin-content-management`
- `admin-batch-approve`
- `admin-batch-delete`

**User Management:**
- `admin-user-management`
- `admin-users-ban`
- `admin-users-unban`

**Comment Moderation:**
- `admin-comment-moderation`

### Client Integration

#### Flutter Mobile Client

**1. Service Registration:**

```dart
// In dependency injection setup
@module
abstract class SecurityModule {
  @lazySingleton
  CsrfService provideCsrfService(Dio dio) {
    return CsrfService(dio, Environment.apiBaseUrl);
  }
}
```

**2. API Client Setup:**

```dart
class ApiClient {
  final Dio _dio;
  final CsrfService _csrfService;

  ApiClient(this._dio, this._csrfService) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    // CSRF interceptor must be first
    _dio.interceptors.add(CsrfInterceptor(_csrfService));
    
    // Other interceptors...
  }
}
```

**3. Automatic Token Management:**

The CSRF interceptor automatically:
- Fetches tokens before first request
- Adds tokens to request headers
- Refreshes expired tokens
- Retries failed requests after token refresh

#### Admin Dashboard

**1. Service Integration:**

```dart
class AdminApiService {
  final SupabaseClient _supabase;
  late final CsrfService _csrfService;

  AdminApiService() {
    _csrfService = CsrfService(_supabase);
  }

  Future<Map<String, String>> get _headers async {
    final csrfToken = await _csrfService.getCsrfToken();
    
    return {
      'Authorization': 'Bearer ${session.accessToken}',
      'X-CSRF-Token': csrfToken,
    };
  }
}
```

## Token Lifecycle

### 1. Token Acquisition

**Client Request:**
```http
GET /csrf-token HTTP/1.1
Authorization: Bearer <access_token>
```

**Server Response:**
```json
{
  "success": true,
  "data": {
    "csrf_token": "abc123...xyz:1234567890",
    "expires_in": 3600
  }
}
```

**Set-Cookie Header:**
```
Set-Cookie: csrf_token=abc123...xyz:1234567890; HttpOnly; Secure; SameSite=Strict; Max-Age=3600; Path=/
```

### 2. Token Usage

**Client Request:**
```http
POST /admin-batch-approve HTTP/1.1
Authorization: Bearer <access_token>
X-CSRF-Token: abc123...xyz:1234567890
Cookie: csrf_token=abc123...xyz:1234567890
Content-Type: application/json

{
  "content_ids": ["uuid1", "uuid2"],
  "status": "approved"
}
```

**Server Validation:**
1. Extract token from Cookie
2. Extract token from Header
3. Compare tokens (constant-time)
4. Check token expiry
5. Verify token in database
6. Verify token belongs to user

### 3. Token Refresh

**Automatic Refresh:**
- Client checks expiry before each request
- Refreshes if expiring within 5 minutes
- Retries failed requests after refresh

**Manual Refresh:**
```http
POST /csrf-token HTTP/1.1
Authorization: Bearer <access_token>
```

### 4. Token Revocation

**On Logout:**
```http
DELETE /csrf-token HTTP/1.1
Authorization: Bearer <access_token>
```

**Server Action:**
- Deletes all user's tokens from database
- Clears cookie

## Error Handling

### Client-Side Errors

**Token Fetch Failed:**
```dart
try {
  final token = await csrfService.getCsrfToken();
} catch (e) {
  // Show error to user
  // Retry or redirect to login
}
```

**CSRF Validation Failed (403):**
```dart
// Interceptor automatically:
// 1. Refreshes token
// 2. Retries request
// 3. Returns error if retry fails
```

### Server-Side Errors

**Missing Token:**
```json
{
  "error": "CSRF token missing in cookie"
}
```

**Expired Token:**
```json
{
  "error": "CSRF token expired"
}
```

**Invalid Token:**
```json
{
  "error": "CSRF token mismatch"
}
```

**Database Validation Failed:**
```json
{
  "error": "Invalid or expired CSRF token"
}
```

## Testing

### Unit Tests

**Backend:**
```typescript
// Test token generation
Deno.test("generateCsrfToken creates valid token", () => {
  const token = generateCsrfToken();
  assertEquals(token.token.length, 64);
  assert(token.timestamp > 0);
});

// Test token validation
Deno.test("validateCsrfToken rejects expired token", async () => {
  const expiredToken = {
    token: "abc123",
    timestamp: Date.now() - 7200000, // 2 hours ago
  };
  // ... test logic
});
```

**Flutter:**
```dart
test('CsrfService caches valid tokens', () async {
  final service = CsrfService(mockDio, 'https://api.example.com');
  
  final token1 = await service.getCsrfToken();
  final token2 = await service.getCsrfToken();
  
  expect(token1, equals(token2));
  verify(mockDio.get(any)).called(1); // Only one API call
});
```

### Integration Tests

**End-to-End Flow:**
```typescript
Deno.test("CSRF protection prevents unauthorized requests", async () => {
  // 1. Get CSRF token
  const tokenResponse = await fetch("/csrf-token");
  const { csrf_token } = await tokenResponse.json();
  
  // 2. Make request without token - should fail
  const failResponse = await fetch("/admin-batch-approve", {
    method: "POST",
    body: JSON.stringify({ content_ids: ["uuid1"] }),
  });
  assertEquals(failResponse.status, 403);
  
  // 3. Make request with token - should succeed
  const successResponse = await fetch("/admin-batch-approve", {
    method: "POST",
    headers: {
      "X-CSRF-Token": csrf_token,
      "Cookie": `csrf_token=${csrf_token}`,
    },
    body: JSON.stringify({ content_ids: ["uuid1"] }),
  });
  assertEquals(successResponse.status, 200);
});
```

## Security Considerations

### Threat Model

**Protected Against:**
- ✅ Cross-Site Request Forgery (CSRF)
- ✅ Token replay attacks (expiry + database validation)
- ✅ Timing attacks (constant-time comparison)
- ✅ Session fixation (token tied to user session)

**Not Protected Against:**
- ❌ XSS attacks (requires separate Content Security Policy)
- ❌ Man-in-the-middle (requires HTTPS)
- ❌ Compromised client (malware on user device)

### Best Practices

1. **Always use HTTPS in production**
   - Prevents token interception
   - Enables Secure cookie flag

2. **Implement Content Security Policy**
   - Prevents XSS attacks
   - Complements CSRF protection

3. **Monitor token usage**
   - Track `last_used_at` in database
   - Alert on suspicious patterns

4. **Regular token rotation**
   - Refresh tokens periodically
   - Clear old tokens on logout

5. **Rate limiting**
   - Limit token generation requests
   - Prevent token exhaustion attacks

## Troubleshooting

### Common Issues

**Issue: "CSRF token missing in cookie"**
- **Cause**: Client not sending cookies
- **Solution**: Ensure `withCredentials: true` in HTTP client

**Issue: "CSRF token expired"**
- **Cause**: Token older than 1 hour
- **Solution**: Client should auto-refresh; check interceptor

**Issue: "CSRF token mismatch"**
- **Cause**: Cookie and header tokens don't match
- **Solution**: Ensure client sends same token in both

**Issue: "Invalid or expired CSRF token" (database)**
- **Cause**: Token not found in database or expired
- **Solution**: Refresh token; check database connectivity

### Debug Mode

**Enable verbose logging:**

```typescript
// Backend
const DEBUG_CSRF = Deno.env.get("DEBUG_CSRF") === "true";

if (DEBUG_CSRF) {
  console.log("CSRF Token:", {
    cookieToken,
    headerToken,
    userId,
    timestamp: new Date().toISOString(),
  });
}
```

```dart
// Flutter
class CsrfService {
  static const bool _debug = true; // Set to false in production
  
  Future<String> getCsrfToken() async {
    if (_debug) {
      print('[CSRF] Fetching token...');
    }
    // ...
  }
}
```

## Performance Optimization

### Caching Strategy

**Client-Side:**
- Memory cache (in-process)
- Persistent cache (SharedPreferences)
- 5-minute early refresh

**Server-Side:**
- Database indexes on `token` and `user_id`
- Automatic cleanup of expired tokens
- Connection pooling

### Monitoring

**Metrics to Track:**
- Token generation rate
- Token validation success/failure rate
- Average token lifetime
- Database query performance

**Alerts:**
- High token generation rate (potential attack)
- High validation failure rate (misconfiguration)
- Slow database queries (performance issue)

## Migration Guide

### Existing Projects

**Step 1: Deploy Backend Changes**
```bash
# Run migration
supabase db push

# Deploy updated functions
./deploy.sh
```

**Step 2: Update Clients**
```bash
# Flutter client
cd dacong-client
flutter pub get
# Update API client initialization

# Admin dashboard
cd dacong-admin
flutter pub get
# Update API service initialization
```

**Step 3: Verify**
```bash
# Test token endpoint
curl https://api.example.com/csrf-token

# Test protected endpoint
curl -X POST https://api.example.com/admin-batch-approve \
  -H "X-CSRF-Token: <token>" \
  -H "Cookie: csrf_token=<token>"
```

## References

- [OWASP CSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html)
- [Double Submit Cookie Pattern](https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html#double-submit-cookie)
- [Supabase Edge Functions Security](https://supabase.com/docs/guides/functions/security)

## Support

For issues or questions:
- Check troubleshooting section above
- Review server logs for detailed error messages
- Contact security team for security-related concerns
