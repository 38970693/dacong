# DaCong API Deployment Guide

## Prerequisites

- Supabase CLI installed: `npm install -g supabase`
- Deno installed: `curl -fsSL https://deno.land/install.sh | sh`
- Git repository access
- Supabase project created

## Environment Setup

### 1. Local Development

```bash
# Clone repository
git clone <repository-url>
cd dacong-api

# Start Supabase locally
supabase start

# Set environment variables
cp .env.example .env
```

### 2. Environment Variables

Create `.env` file:

```bash
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Frontend
FRONTEND_URL=https://your-frontend.com

# Sentry (optional)
SENTRY_DSN=https://your-sentry-dsn

# Environment
ENVIRONMENT=production
```

## Database Migration

### 1. Apply Migrations

```bash
# Link to your Supabase project
supabase link --project-ref your-project-ref

# Apply all migrations
supabase db push

# Or apply specific migration
supabase migration up --file 20260419000001_create_audit_logs.sql
```

### 2. Verify Migrations

```bash
# Check migration status
supabase migration list

# Check database schema
supabase db diff
```

### 3. Create First Admin User

```sql
-- Connect to your database
-- Update user role to admin (replace with your user ID)
UPDATE user_roles 
SET role = 'admin', 
    permissions = '{"manage_system": true}'::jsonb
WHERE user_id = '<your-user-id>';
```

## Deploy Edge Functions

### 1. Deploy All Functions

```bash
# Deploy all functions
supabase functions deploy

# Or deploy specific function
supabase functions deploy auth-login
supabase functions deploy auth-register
supabase functions deploy favorites-add
```

### 2. Set Function Secrets

```bash
# Set environment variables for functions
supabase secrets set SUPABASE_URL=https://your-project.supabase.co
supabase secrets set SUPABASE_ANON_KEY=your-anon-key
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
supabase secrets set FRONTEND_URL=https://your-frontend.com
supabase secrets set SENTRY_DSN=https://your-sentry-dsn
supabase secrets set ENVIRONMENT=production

# List all secrets
supabase secrets list
```

### 3. Verify Deployment

```bash
# Test function
curl -X POST https://your-project.supabase.co/functions/v1/auth-login \
  -H "Authorization: Bearer your-anon-key" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'
```

## Function List

### Authentication Functions
- `auth-register` - User registration
- `auth-login` - User login
- `auth-logout` - User logout
- `auth-refresh` - Refresh access token
- `auth-reset-password` - Password reset request
- `auth-change-password` - Change password
- `auth-verify-email` - Email verification

### Favorites Functions
- `favorites-add` - Add to favorites
- `favorites-remove` - Remove from favorites
- `favorites-check` - Check if favorited
- `get-favorites` - Get favorites list (existing)

### Admin Functions
- `admin-users-list` - List all users
- `admin-users-ban` - Ban user
- `admin-users-unban` - Unban user
- `admin-audit-logs` - View audit logs
- `admin-stats` - View statistics
- `admin-batch-approve` - Batch approve content
- `admin-batch-delete` - Batch delete content

## Testing

### 1. Run Tests Locally

```bash
# Set test environment variables
export SUPABASE_URL="http://localhost:54321"
export SUPABASE_ANON_KEY="your-local-anon-key"
export TEST_USER_EMAIL="test@example.com"
export TEST_USER_PASSWORD="TestPassword123!"
export TEST_ADMIN_EMAIL="admin@example.com"
export TEST_ADMIN_PASSWORD="AdminPassword123!"

# Run all tests
deno test --allow-net --allow-env supabase/functions/tests/

# Run with coverage
deno test --allow-net --allow-env --coverage=coverage supabase/functions/tests/
deno coverage coverage
```

### 2. Integration Testing

```bash
# Test auth flow
curl -X POST $SUPABASE_URL/functions/v1/auth-register \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123!","username":"testuser"}'

# Test favorites
curl -X POST $SUPABASE_URL/functions/v1/favorites-add \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content_id":"uuid-here"}'
```

## Monitoring

### 1. Sentry Setup

Sentry is already integrated. Errors are automatically captured and sent to Sentry.

### 2. View Logs

```bash
# View function logs
supabase functions logs auth-login

# Follow logs in real-time
supabase functions logs auth-login --follow
```

### 3. Performance Monitoring

Check Supabase dashboard for:
- Function invocation count
- Average execution time
- Error rate
- Memory usage

## Security Checklist

- [ ] All environment variables set
- [ ] Service role key kept secret
- [ ] RLS policies enabled on all tables
- [ ] Rate limiting configured
- [ ] CORS properly configured
- [ ] Admin users properly assigned
- [ ] Audit logging enabled
- [ ] Sentry monitoring active

## Rollback Procedure

### 1. Rollback Migration

```bash
# Rollback last migration
supabase migration down

# Rollback to specific version
supabase migration down --version 20260419000001
```

### 2. Rollback Function

```bash
# Deploy previous version
git checkout <previous-commit>
supabase functions deploy <function-name>
```

## Troubleshooting

### Function Not Working

1. Check logs: `supabase functions logs <function-name>`
2. Verify secrets: `supabase secrets list`
3. Test locally: `supabase functions serve <function-name>`

### Database Issues

1. Check migration status: `supabase migration list`
2. Verify RLS policies: Check Supabase dashboard
3. Check table permissions

### Authentication Issues

1. Verify JWT secret matches
2. Check user_roles table
3. Verify RLS policies on auth tables

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy to Supabase

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Supabase CLI
        uses: supabase/setup-cli@v1
        
      - name: Link Supabase project
        run: supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
          
      - name: Deploy migrations
        run: supabase db push
        
      - name: Deploy functions
        run: supabase functions deploy
```

## Performance Optimization

### 1. Database Indexes

All necessary indexes are created in migrations. Monitor slow queries in Supabase dashboard.

### 2. Function Cold Starts

Functions may have cold starts. Consider:
- Keeping functions warm with periodic pings
- Using Supabase's function warming feature

### 3. Rate Limiting

Rate limiting is configured per function. Adjust in middleware if needed.

## Support

For issues or questions:
- Check Supabase documentation: https://supabase.com/docs
- Review function logs
- Check audit logs for admin operations
