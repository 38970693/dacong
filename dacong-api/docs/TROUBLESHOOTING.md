# DaCong API Troubleshooting Guide

## Common Issues

### 1. Function Deployment Fails

#### Symptom
```bash
Error: Failed to deploy function
```

#### Solutions

**Check function syntax:**
```bash
# Lint function locally
deno lint supabase/functions/my-function/index.ts

# Type check
deno check supabase/functions/my-function/index.ts
```

**Verify imports:**
```typescript
// ✅ Good: Use versioned imports
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// ❌ Bad: Unversioned imports
import { serve } from "https://deno.land/std/http/server.ts";
```

**Check function size:**
```bash
# Functions must be < 10MB
du -sh supabase/functions/my-function/
```

### 2. Authentication Errors

#### Symptom
```json
{
  "success": false,
  "error": "Invalid or expired token"
}
```

#### Solutions

**Verify token format:**
```bash
# Token should be in format: Bearer <jwt-token>
curl -H "Authorization: Bearer eyJh..." <url>
```

**Check token expiry:**
```typescript
// Decode JWT to check expiry
const payload = JSON.parse(atob(token.split('.')[1]));
console.log('Expires:', new Date(payload.exp * 1000));
```

**Refresh token:**
```bash
curl -X POST $SUPABASE_URL/functions/v1/auth-refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"<refresh-token>"}'
```

### 3. Database Connection Issues

#### Symptom
```
Error: Connection refused
```

#### Solutions

**Check Supabase is running:**
```bash
# Local development
supabase status

# If not running
supabase start
```

**Verify connection string:**
```bash
# Check environment variables
echo $SUPABASE_URL
echo $SUPABASE_ANON_KEY
```

**Test connection:**
```bash
curl $SUPABASE_URL/rest/v1/ \
  -H "apikey: $SUPABASE_ANON_KEY"
```

### 4. Migration Errors

#### Symptom
```
Error: Migration failed
```

#### Solutions

**Check migration syntax:**
```bash
# Validate SQL
psql -f supabase/migrations/my_migration.sql --dry-run
```

**Rollback and retry:**
```bash
# Rollback last migration
supabase migration down

# Fix migration file
# Then apply again
supabase db push
```

**Check for conflicts:**
```sql
-- Check if table already exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_name = 'my_table';
```

### 5. Rate Limiting Issues

#### Symptom
```json
{
  "success": false,
  "error": "Too many requests"
}
```

#### Solutions

**Wait for rate limit reset:**
```bash
# Check Retry-After header
curl -I $URL | grep Retry-After
```

**Adjust rate limits:**
```typescript
// In function code
const rateLimiter = createRateLimiter({
  maxRequests: 100,  // Increase limit
  windowMs: 60 * 1000,
});
```

**Use authentication:**
```bash
# Authenticated requests have higher limits
curl -H "Authorization: Bearer <token>" $URL
```

### 6. CORS Errors

#### Symptom
```
Access to fetch blocked by CORS policy
```

#### Solutions

**Check CORS headers:**
```bash
curl -I -X OPTIONS $URL \
  -H "Origin: https://your-frontend.com"
```

**Update CORS configuration:**
```typescript
// In _shared/utils/http.ts
headers: {
  "Access-Control-Allow-Origin": "https://your-frontend.com",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type",
}
```

**Handle preflight requests:**
```typescript
if (req.method === "OPTIONS") {
  return corsResponse();
}
```

### 7. Permission Denied Errors

#### Symptom
```json
{
  "success": false,
  "error": "Insufficient permissions"
}
```

#### Solutions

**Check user role:**
```sql
SELECT role, permissions 
FROM user_roles 
WHERE user_id = '<user-id>';
```

**Grant permissions:**
```sql
UPDATE user_roles 
SET permissions = permissions || '{"view_users": true}'::jsonb
WHERE user_id = '<user-id>';
```

**Verify RLS policies:**
```sql
-- Check policies on table
SELECT * FROM pg_policies WHERE tablename = 'my_table';
```

### 8. Test Failures

#### Symptom
```
Test failed: Expected 200, got 500
```

#### Solutions

**Check test environment:**
```bash
# Ensure test database is clean
supabase db reset

# Reapply migrations
supabase db push
```

**Create test data:**
```sql
-- Create test user
INSERT INTO auth.users (id, email) 
VALUES ('test-uuid', 'test@example.com');

-- Assign role
INSERT INTO user_roles (user_id, role) 
VALUES ('test-uuid', 'admin');
```

**Enable debug logging:**
```typescript
// In test file
Deno.env.set("DEBUG", "true");
```

### 9. Slow Function Performance

#### Symptom
Functions taking > 3 seconds to respond

#### Solutions

**Profile database queries:**
```typescript
const start = Date.now();
const { data } = await supabase.from('table').select('*');
console.log(`Query took ${Date.now() - start}ms`);
```

**Add database indexes:**
```sql
-- Check missing indexes
SELECT * FROM pg_stat_user_tables WHERE idx_scan = 0;

-- Add index
CREATE INDEX idx_table_column ON table(column);
```

**Optimize queries:**
```typescript
// ✅ Good: Select only needed fields
.select('id, name')

// ❌ Bad: Select all fields
.select('*')

// ✅ Good: Use pagination
.range(0, 19)

// ❌ Bad: Load all records
.select('*')
```

### 10. Sentry Not Capturing Errors

#### Symptom
Errors not appearing in Sentry dashboard

#### Solutions

**Verify DSN:**
```bash
# Check Sentry DSN is set
supabase secrets list | grep SENTRY_DSN
```

**Test Sentry:**
```typescript
import { captureMessage } from "../_shared/utils/sentry.ts";

// Send test message
captureMessage("Test message", "info");
```

**Check initialization:**
```typescript
// Ensure Sentry is initialized
initSentry({ 
  functionName: "my-function",
  debug: true  // Enable debug mode
});
```

## Debugging Tools

### 1. View Function Logs

```bash
# Real-time logs
supabase functions logs my-function --follow

# Last 100 lines
supabase functions logs my-function --tail 100

# Filter by level
supabase functions logs my-function --level error
```

### 2. Database Logs

```bash
# View database logs
supabase db logs --follow

# Filter by query type
supabase db logs --filter "SELECT"
```

### 3. Local Testing

```bash
# Serve function locally
supabase functions serve my-function --env-file .env.local

# Test with curl
curl -X POST http://localhost:54321/functions/v1/my-function \
  -H "Authorization: Bearer <anon-key>" \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'
```

### 4. Database Inspection

```bash
# Connect to database
supabase db shell

# Run queries
SELECT * FROM user_roles LIMIT 10;
SELECT * FROM audit_logs ORDER BY created_at DESC LIMIT 10;
```

### 5. Network Debugging

```bash
# Check DNS resolution
nslookup your-project.supabase.co

# Test connectivity
curl -v https://your-project.supabase.co

# Check SSL certificate
openssl s_client -connect your-project.supabase.co:443
```

## Getting Help

### 1. Check Documentation
- [Supabase Docs](https://supabase.com/docs)
- [Deno Manual](https://deno.land/manual)
- Project documentation in `/docs`

### 2. Search Issues
- Check GitHub issues
- Search Supabase Discord
- Stack Overflow

### 3. Create Issue
Include:
- Error message
- Function logs
- Steps to reproduce
- Environment (local/production)
- Supabase CLI version

### 4. Contact Support
- Supabase support (for platform issues)
- Project maintainers (for code issues)

## Prevention

### 1. Pre-deployment Checklist
- [ ] All tests passing
- [ ] Migrations applied
- [ ] Environment variables set
- [ ] Functions linted
- [ ] No console.log in production code

### 2. Monitoring Setup
- [ ] Sentry configured
- [ ] Alerts set up
- [ ] Log retention configured
- [ ] Performance monitoring enabled

### 3. Backup Strategy
- [ ] Database backups enabled
- [ ] Function versions tagged
- [ ] Configuration documented
- [ ] Rollback plan ready
