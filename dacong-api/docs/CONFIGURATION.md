# DaCong API Configuration Guide

## Environment Variables

### Required Variables

```bash
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Frontend Configuration
FRONTEND_URL=https://your-frontend.com
```

### Optional Variables

```bash
# Monitoring
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id
ENVIRONMENT=production  # development, staging, production

# Rate Limiting (defaults shown)
RATE_LIMIT_MAX_REQUESTS=60
RATE_LIMIT_WINDOW_MS=60000

# Email Configuration (if using custom SMTP)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=your-email@example.com
SMTP_PASSWORD=your-password
```

## Function Configuration

### Rate Limiting

Each function can have custom rate limiting. Edit in function code:

```typescript
import { createRateLimiter, RateLimitPresets } from "../_shared/middleware/rate_limiter.ts";

// Use preset
const rateLimiter = createRateLimiter(RateLimitPresets.standard);

// Or custom configuration
const rateLimiter = createRateLimiter({
  maxRequests: 30,
  windowMs: 60 * 1000,
  message: "Custom rate limit message",
});
```

### Available Presets

- `strict`: 10 requests/minute
- `standard`: 30 requests/minute
- `relaxed`: 100 requests/minute
- `search`: 20 requests/minute
- `feedback`: 10 requests/hour

### CORS Configuration

CORS is configured in `_shared/utils/http.ts`:

```typescript
headers: {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}
```

To restrict origins, modify:

```typescript
"Access-Control-Allow-Origin": Deno.env.get("FRONTEND_URL") || "*",
```

## Database Configuration

### Row Level Security (RLS)

All tables have RLS enabled. Policies are defined in migrations.

### User Roles

Three roles are supported:
- `admin`: Full access to all features
- `moderator`: Content moderation and user management
- `user`: Standard user access

### Permissions

Permissions are stored in `user_roles.permissions` as JSONB:

```json
{
  "view_users": true,
  "manage_users": true,
  "ban_users": true,
  "moderate_content": true,
  "delete_content": true,
  "view_audit_logs": true
}
```

## Middleware Configuration

### Authentication Middleware

Located in `_shared/middleware/auth.ts`:

```typescript
// Require any authenticated user
const { user, supabase } = await requireAuth(req);

// Require admin or moderator
const { user, supabase } = await requireAdmin(req);

// Require super admin only
const { user, supabase } = await requireSuperAdmin(req);

// Check specific permission
requirePermission(user, Permissions.BAN_USERS);
```

### Validation Middleware

Using Zod for input validation. Schemas in `_shared/schemas/`:

```typescript
import { registerSchema, validateInput } from "../_shared/schemas/auth_schemas.ts";

const body = await getRequestBody(req);
const input = validateInput(registerSchema, body);
```

### Audit Logging

Automatically log admin actions:

```typescript
import { logAudit, AuditActions, AuditResources, extractAuditInfo } from "../_shared/utils/audit.ts";

const { ipAddress, userAgent } = extractAuditInfo(req);
await logAudit(supabase, {
  userId: user.id,
  action: AuditActions.USER_BAN,
  resource: AuditResources.USER,
  resourceId: targetUserId,
  ipAddress,
  userAgent,
  status: "success",
  details: { reason: "Spam" },
});
```

## Sentry Configuration

### Initialization

Sentry is initialized in each function:

```typescript
import { initSentry, withSentry } from "../_shared/utils/sentry.ts";

initSentry({ functionName: "my-function" });

serve(
  withSentry(
    async (req) => {
      // Your handler
    },
    {
      functionName: "my-function",
      captureErrors: true,
    }
  )
);
```

### Custom Error Tracking

```typescript
import { captureException, captureMessage, addBreadcrumb } from "../_shared/utils/sentry.ts";

// Capture exception
try {
  // risky operation
} catch (error) {
  captureException(error, "Operation failed", "error");
}

// Capture message
captureMessage("Important event occurred", "info");

// Add breadcrumb
addBreadcrumb({
  message: "User action",
  category: "user",
  level: "info",
  data: { action: "click" },
});
```

## Security Configuration

### Password Requirements

Configured in `_shared/schemas/auth_schemas.ts`:

```typescript
password: z
  .string()
  .min(8, "Password must be at least 8 characters")
  .max(128, "Password must be less than 128 characters")
  .regex(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
    "Password must contain uppercase, lowercase, and number"
  )
```

### JWT Configuration

JWT tokens are managed by Supabase Auth. Configure in Supabase dashboard:
- Token expiry time
- Refresh token rotation
- JWT secret

### IP Blocking

To block specific IPs, add to rate limiter:

```typescript
const blockedIPs = ["1.2.3.4", "5.6.7.8"];

function getClientIdentifier(req: Request): string {
  const ip = req.headers.get("x-forwarded-for") || "unknown";
  
  if (blockedIPs.includes(ip)) {
    throw new Error("IP blocked");
  }
  
  return `ip:${ip}`;
}
```

## Performance Configuration

### Database Connection Pooling

Supabase handles connection pooling automatically. For custom configuration, contact Supabase support.

### Function Timeout

Default timeout is 60 seconds. Cannot be changed for Edge Functions.

### Memory Limits

Edge Functions have 150MB memory limit. Monitor usage in Supabase dashboard.

## Logging Configuration

### Log Levels

Configure in Sentry initialization:

```typescript
initSentry({
  functionName: "my-function",
  debug: Deno.env.get("ENVIRONMENT") === "development",
  tracesSampleRate: 0.2, // 20% of transactions
});
```

### Custom Logging

```typescript
// Development logging
if (Deno.env.get("ENVIRONMENT") === "development") {
  console.log("Debug info:", data);
}

// Production logging (goes to Supabase logs)
console.error("Error occurred:", error);
console.warn("Warning:", warning);
console.info("Info:", info);
```

## Backup Configuration

### Database Backups

Supabase provides automatic daily backups. Configure in dashboard:
- Backup retention period
- Point-in-time recovery
- Manual backup triggers

### Function Versioning

Use Git tags for function versions:

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

## Scaling Configuration

### Auto-scaling

Supabase Edge Functions auto-scale based on demand. No configuration needed.

### Database Scaling

Monitor database performance in Supabase dashboard. Upgrade plan if needed.

### CDN Configuration

For static assets, use Supabase Storage with CDN enabled.

## Troubleshooting

### Enable Debug Mode

```bash
# Set environment variable
supabase secrets set DEBUG=true

# Check function logs
supabase functions logs <function-name> --follow
```

### Performance Profiling

```typescript
const start = Date.now();
// operation
const duration = Date.now() - start;

if (duration > 1000) {
  console.warn(`Slow operation: ${duration}ms`);
}
```

### Database Query Debugging

```typescript
const { data, error } = await supabase
  .from("table")
  .select("*")
  .explain(); // Shows query plan

console.log("Query plan:", data);
```
