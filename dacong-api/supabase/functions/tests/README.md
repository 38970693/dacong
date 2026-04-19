# Test Suite for DaCong Edge Functions

## Overview
Comprehensive test suite for Supabase Edge Functions with 80%+ coverage target.

## Prerequisites

```bash
# Set environment variables
export SUPABASE_URL="http://localhost:54321"
export SUPABASE_ANON_KEY="your-anon-key"
export TEST_USER_EMAIL="test@example.com"
export TEST_USER_PASSWORD="TestPassword123!"
export TEST_ADMIN_EMAIL="admin@example.com"
export TEST_ADMIN_PASSWORD="AdminPassword123!"
```

## Running Tests

### Run all tests
```bash
deno test --allow-net --allow-env supabase/functions/tests/
```

### Run specific test file
```bash
deno test --allow-net --allow-env supabase/functions/tests/auth.test.ts
deno test --allow-net --allow-env supabase/functions/tests/favorites.test.ts
deno test --allow-net --allow-env supabase/functions/tests/admin.test.ts
```

### Run with coverage
```bash
deno test --allow-net --allow-env --coverage=coverage supabase/functions/tests/
deno coverage coverage --lcov > coverage.lcov
```

## Test Structure

### Auth Tests (`auth.test.ts`)
- ✅ User registration
- ✅ Duplicate username validation
- ✅ Login with valid credentials
- ✅ Login with invalid credentials
- ✅ Token refresh
- ✅ Logout
- ✅ Password reset request

### Favorites Tests (`favorites.test.ts`)
- ✅ Add favorite
- ✅ Duplicate favorite validation
- ✅ Check if favorited
- ✅ Get favorites list
- ✅ Remove favorite
- ✅ Check after removal

### Admin Tests (`admin.test.ts`)
- ✅ Get users list
- ✅ Ban user
- ✅ Unban user
- ✅ Get audit logs
- ✅ Get statistics
- ✅ Batch approve content
- ✅ Non-admin access denied

## Test Data Setup

Before running tests, ensure you have:

1. A test user account
2. An admin user account
3. Sample content for testing favorites

You can create these using the Supabase dashboard or SQL:

```sql
-- Create test admin user
UPDATE user_roles SET role = 'admin' WHERE user_id = '<test-admin-user-id>';

-- Create sample content
INSERT INTO published_content (title_zh, summary_zh, content_type, scenario)
VALUES ('Test Content', 'Test Summary', 'article', 'general');
```

## Coverage Goals

- **Target**: 80%+ coverage
- **Current**: Run `deno coverage` to check

## CI/CD Integration

Add to your CI pipeline:

```yaml
test:
  script:
    - deno test --allow-net --allow-env --coverage=coverage supabase/functions/tests/
    - deno coverage coverage --lcov > coverage.lcov
  coverage: '/\d+\.\d+% coverage/'
```

## Troubleshooting

### Connection refused
- Ensure Supabase is running locally: `supabase start`
- Check SUPABASE_URL is correct

### Authentication errors
- Verify test user credentials
- Check user_roles table has correct permissions

### Test failures
- Check database state
- Ensure migrations are applied
- Verify RLS policies are correct
