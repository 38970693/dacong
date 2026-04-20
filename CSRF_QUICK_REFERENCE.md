# CSRF Protection Quick Reference

## For Developers

### Backend: Adding CSRF Protection to New Endpoints

```typescript
import { csrfMiddleware } from "../_shared/middleware/csrf.ts";
import { requireAdmin } from "../_shared/middleware/admin.ts";

// For authenticated endpoints
serve(async (req) => {
  const { user, supabase } = await requireAdmin(req);
  
  // Add CSRF validation
  const csrfError = await csrfMiddleware(req, supabase, user.id);
  if (csrfError) return csrfError;
  
  // Your business logic here
});

// For public endpoints (login, register)
serve(async (req) => {
  // Add CSRF validation (no user verification)
  const csrfError = await csrfMiddleware(req);
  if (csrfError) return csrfError;
  
  // Your business logic here
});
```

### Flutter Client: Using CSRF Service

```dart
// Service is automatically injected via dependency injection
// CSRF tokens are automatically added to all POST/PUT/PATCH/DELETE requests

// Manual token management (rarely needed)
final csrfService = getIt<CsrfService>();

// Get token
final token = await csrfService.getCsrfToken();

// Refresh token
await csrfService.refreshToken();

// Clear token (on logout)
await csrfService.clearToken();
```

### Admin Dashboard: Using CSRF Service

```dart
// CSRF tokens are automatically added via AdminApiService
// No manual intervention needed

// The service handles everything:
final apiService = AdminApiService();
await apiService.moderateContent(
  action: 'approve',
  contentIds: ['uuid1', 'uuid2'],
);
// CSRF token is automatically included
```

## Common Issues & Solutions

### Issue: "CSRF token missing in cookie"
**Cause**: Client not sending cookies  
**Solution**: Ensure cookies are enabled; check CORS configuration

### Issue: "CSRF token expired"
**Cause**: Token older than 1 hour  
**Solution**: Client should auto-refresh; verify interceptor is working

### Issue: "CSRF token mismatch"
**Cause**: Cookie and header tokens don't match  
**Solution**: Ensure client sends same token in both places

### Issue: "Invalid or expired CSRF token"
**Cause**: Token not found in database  
**Solution**: Refresh token; check database connectivity

## Testing

### Run Unit Tests
```bash
cd dacong-api/supabase/functions
deno test tests/csrf_middleware_test.ts
```

### Run Integration Tests
```bash
cd dacong-api/supabase/functions
deno test tests/csrf_integration_test.ts --allow-net --allow-env
```

### Manual Testing
```bash
# Get CSRF token
curl https://api.dacong.app/functions/v1/csrf-token

# Use token in request
curl -X POST https://api.dacong.app/functions/v1/auth-login \
  -H "X-CSRF-Token: <token>" \
  -H "Cookie: csrf_token=<token>" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!@#"}'
```

## Monitoring

### Key Metrics
- CSRF validation success rate (should be >99%)
- Token generation rate (monitor for spikes)
- Token validation latency (should be <10ms)
- Database query performance

### Alerts
- High CSRF validation failure rate (>1%)
- Unusual token generation patterns
- Slow database queries (>100ms)

## Security Checklist

- [ ] HTTPS enforced in production
- [ ] CSRF middleware on all POST/PUT/PATCH/DELETE endpoints
- [ ] Security headers configured
- [ ] Rate limiting enabled
- [ ] Audit logging enabled
- [ ] Error monitoring configured
- [ ] Regular security audits scheduled

## Quick Links

- [Full Documentation](docs/security/CSRF_PROTECTION.md)
- [Security Best Practices](docs/security/SECURITY_BEST_PRACTICES.md)
- [Implementation Summary](CSRF_IMPLEMENTATION_SUMMARY.md)
- [Deployment Script](deploy-csrf.sh)

## Support

- Security issues: security@dacong.app
- Documentation: `docs/security/`
- Code examples: `_shared/middleware/csrf_integration_example.ts`
