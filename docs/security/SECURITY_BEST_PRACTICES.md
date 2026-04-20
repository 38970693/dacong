# Security Best Practices

## Overview

This document outlines security best practices for the DaCong project, covering authentication, authorization, data protection, and secure coding practices.

## Authentication & Authorization

### Password Security

**Requirements:**
- Minimum 8 characters
- Mix of uppercase, lowercase, numbers, and symbols
- No common passwords (use password strength checker)
- Bcrypt hashing with salt (handled by Supabase Auth)

**Implementation:**
```typescript
// Backend validation
const passwordSchema = z.string()
  .min(8, "Password must be at least 8 characters")
  .regex(/[A-Z]/, "Password must contain uppercase letter")
  .regex(/[a-z]/, "Password must contain lowercase letter")
  .regex(/[0-9]/, "Password must contain number")
  .regex(/[^A-Za-z0-9]/, "Password must contain special character");
```

### Session Management

**Best Practices:**
- Use short-lived access tokens (1 hour)
- Implement refresh token rotation
- Clear sessions on logout
- Invalidate sessions on password change
- Monitor for suspicious session activity

**Implementation:**
```typescript
// Logout: Clear all user sessions
await supabase.auth.signOut();
await clearUserCsrfTokens(supabase, userId);
```

### Multi-Factor Authentication (MFA)

**Recommended for:**
- Admin accounts (mandatory)
- User accounts with sensitive data (optional)

**Implementation:**
```typescript
// Enable MFA for admin users
const { data, error } = await supabase.auth.mfa.enroll({
  factorType: 'totp',
});
```

## Input Validation

### Server-Side Validation

**Always validate on the server:**
```typescript
import { z } from "zod";

const createContentSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1).max(10000),
  topic_id: z.string().uuid(),
  tags: z.array(z.string()).max(10),
});

// Validate input
const validated = createContentSchema.parse(body);
```

### SQL Injection Prevention

**Use parameterized queries:**
```typescript
// WRONG: String concatenation
const { data } = await supabase
  .from('users')
  .select('*')
  .eq('username', `${userInput}`); // Vulnerable!

// CORRECT: Parameterized query
const { data } = await supabase
  .from('users')
  .select('*')
  .eq('username', userInput); // Safe
```

### XSS Prevention

**Sanitize HTML output:**
```dart
// Flutter: Use Text widget (auto-escapes)
Text(userInput) // Safe

// For HTML content, use sanitizer
import 'package:html/parser.dart' as html_parser;

String sanitizeHtml(String input) {
  final document = html_parser.parse(input);
  return document.body?.text ?? '';
}
```

**Content Security Policy:**
```typescript
// Add CSP headers
headers.set('Content-Security-Policy', 
  "default-src 'self'; " +
  "script-src 'self' 'unsafe-inline'; " +
  "style-src 'self' 'unsafe-inline'; " +
  "img-src 'self' data: https:; " +
  "font-src 'self' data:;"
);
```

## Data Protection

### Sensitive Data Handling

**Never log sensitive data:**
```typescript
// WRONG
console.log('User password:', password);
console.log('Credit card:', creditCard);

// CORRECT
console.log('User authenticated:', userId);
console.log('Payment processed:', transactionId);
```

**Encrypt sensitive data at rest:**
```typescript
// Use Supabase encryption for sensitive columns
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY,
  email TEXT NOT NULL,
  phone TEXT, -- Encrypt if storing
  ssn TEXT -- Never store unless absolutely necessary
);
```

### Personal Identifiable Information (PII)

**GDPR Compliance:**
- Obtain explicit consent for data collection
- Provide data export functionality
- Implement data deletion (right to be forgotten)
- Minimize data collection (only what's needed)

**Implementation:**
```typescript
// Data export
export async function exportUserData(userId: string) {
  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single();
    
  const { data: content } = await supabase
    .from('published_content')
    .select('*')
    .eq('user_id', userId);
    
  return {
    profile,
    content,
    exported_at: new Date().toISOString(),
  };
}

// Data deletion
export async function deleteUserData(userId: string) {
  // Delete in correct order (foreign keys)
  await supabase.from('comments').delete().eq('user_id', userId);
  await supabase.from('published_content').delete().eq('user_id', userId);
  await supabase.from('profiles').delete().eq('id', userId);
  await supabase.auth.admin.deleteUser(userId);
}
```

## API Security

### Rate Limiting

**Implement rate limits:**
```typescript
import { createRateLimiter, RateLimitPresets } from "../_shared/middleware/rate_limiter.ts";

// Strict rate limit for sensitive operations
const rateLimiter = createRateLimiter({
  ...RateLimitPresets.strict,
  maxRequests: 5,
  windowMs: 60000, // 5 requests per minute
});

serve(async (req) => {
  const rateLimitResponse = await rateLimiter(req);
  if (rateLimitResponse) return rateLimitResponse;
  
  // Business logic
});
```

### CORS Configuration

**Restrict origins:**
```typescript
const allowedOrigins = [
  'https://dacong.app',
  'https://admin.dacong.app',
];

function corsResponse(origin?: string): Response {
  const headers = new Headers({
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-CSRF-Token',
    'Access-Control-Max-Age': '86400',
  });
  
  if (origin && allowedOrigins.includes(origin)) {
    headers.set('Access-Control-Allow-Origin', origin);
    headers.set('Access-Control-Allow-Credentials', 'true');
  }
  
  return new Response(null, { status: 204, headers });
}
```

### HTTPS Enforcement

**Always use HTTPS in production:**
```typescript
// Redirect HTTP to HTTPS
if (req.url.startsWith('http://') && 
    Deno.env.get('ENVIRONMENT') === 'production') {
  const httpsUrl = req.url.replace('http://', 'https://');
  return Response.redirect(httpsUrl, 301);
}
```

**Security headers:**
```typescript
const securityHeaders = {
  'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'X-XSS-Protection': '1; mode=block',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
};
```

## Secret Management

### Environment Variables

**Never commit secrets:**
```bash
# .env (add to .gitignore)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc... # NEVER expose to client!

# Use different keys for different environments
ENVIRONMENT=production
```

**Validate secrets at startup:**
```typescript
function validateEnvironment() {
  const required = [
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
    'SUPABASE_SERVICE_ROLE_KEY',
  ];
  
  for (const key of required) {
    if (!Deno.env.get(key)) {
      throw new Error(`Missing required environment variable: ${key}`);
    }
  }
}

validateEnvironment();
```

### API Key Rotation

**Regular rotation schedule:**
- Service role keys: Every 90 days
- API keys: Every 30 days
- Database passwords: Every 90 days

**Rotation process:**
1. Generate new key
2. Update environment variables
3. Deploy with new key
4. Verify functionality
5. Revoke old key after grace period

## Error Handling

### Secure Error Messages

**Don't leak sensitive information:**
```typescript
// WRONG: Exposes internal details
return errorResponse(`Database error: ${error.message}`, 500);

// CORRECT: Generic message
return errorResponse('An error occurred. Please try again later.', 500);

// Log detailed error server-side
console.error('Database error:', {
  error: error.message,
  stack: error.stack,
  userId,
  timestamp: new Date().toISOString(),
});
```

### Error Monitoring

**Use Sentry for error tracking:**
```typescript
import * as Sentry from "https://deno.land/x/sentry/index.ts";

Sentry.init({
  dsn: Deno.env.get("SENTRY_DSN"),
  environment: Deno.env.get("ENVIRONMENT"),
  beforeSend(event) {
    // Remove sensitive data
    if (event.request?.headers) {
      delete event.request.headers['Authorization'];
      delete event.request.headers['Cookie'];
    }
    return event;
  },
});
```

## Database Security

### Row Level Security (RLS)

**Enable RLS on all tables:**
```sql
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Users can only read their own profile
CREATE POLICY "Users can view own profile"
ON profiles FOR SELECT
USING (auth.uid() = id);

-- Users can only update their own profile
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id);
```

### Audit Logging

**Log all sensitive operations:**
```typescript
await logAudit(supabase, {
  userId: user.id,
  action: AuditActions.USER_DELETE,
  resource: AuditResources.USER,
  ipAddress: req.headers.get('x-forwarded-for'),
  userAgent: req.headers.get('user-agent'),
  status: 'success',
  details: { deletedUserId: targetUserId },
});
```

## Dependency Security

### Regular Updates

**Check for vulnerabilities:**
```bash
# Deno: Check for outdated dependencies
deno outdated

# Flutter: Check for vulnerabilities
flutter pub outdated
dart pub audit
```

**Automated scanning:**
```yaml
# .github/workflows/security.yml
name: Security Scan
on: [push, pull_request]
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Snyk
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

### Supply Chain Security

**Verify package integrity:**
```typescript
// Use specific versions, not ranges
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// Not: "https://deno.land/std/http/server.ts" (latest)
```

## Monitoring & Alerting

### Security Events to Monitor

**Critical events:**
- Failed login attempts (>5 in 5 minutes)
- Admin privilege escalation
- Bulk data exports
- Unusual API usage patterns
- CSRF token validation failures

**Implementation:**
```typescript
// Alert on suspicious activity
if (failedLoginAttempts > 5) {
  await sendAlert({
    severity: 'high',
    message: `Multiple failed login attempts for user ${email}`,
    ip: ipAddress,
    timestamp: new Date().toISOString(),
  });
  
  // Temporarily block IP
  await blockIp(ipAddress, 3600); // 1 hour
}
```

### Incident Response

**Response plan:**
1. **Detect**: Automated monitoring alerts
2. **Assess**: Determine severity and impact
3. **Contain**: Block malicious actors, revoke compromised credentials
4. **Eradicate**: Fix vulnerability, patch systems
5. **Recover**: Restore normal operations
6. **Learn**: Post-mortem analysis, update procedures

## Compliance

### Data Retention

**Define retention policies:**
```sql
-- Delete old audit logs after 1 year
DELETE FROM audit_logs
WHERE created_at < NOW() - INTERVAL '1 year';

-- Archive old content after 2 years
UPDATE published_content
SET archived = true
WHERE created_at < NOW() - INTERVAL '2 years';
```

### Privacy Policy

**Required disclosures:**
- What data is collected
- How data is used
- Who data is shared with
- How long data is retained
- User rights (access, deletion, portability)

## Security Checklist

### Pre-Deployment

- [ ] All secrets in environment variables (not code)
- [ ] HTTPS enforced in production
- [ ] CSRF protection enabled on all state-changing endpoints
- [ ] Rate limiting configured
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (output escaping)
- [ ] Error messages don't leak sensitive info
- [ ] Security headers configured
- [ ] RLS enabled on all tables
- [ ] Audit logging for sensitive operations
- [ ] Dependencies scanned for vulnerabilities
- [ ] MFA enabled for admin accounts

### Post-Deployment

- [ ] Monitor error rates
- [ ] Review audit logs regularly
- [ ] Test backup/restore procedures
- [ ] Conduct security assessments
- [ ] Update dependencies monthly
- [ ] Rotate secrets quarterly
- [ ] Review access permissions
- [ ] Test incident response plan

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [Supabase Security Best Practices](https://supabase.com/docs/guides/platform/security)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)

## Contact

For security concerns or to report vulnerabilities:
- Email: security@dacong.app
- Use responsible disclosure
- Allow 90 days for remediation before public disclosure
