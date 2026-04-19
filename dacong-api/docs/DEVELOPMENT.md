# DaCong API Development Guide

## Getting Started

### Prerequisites

- Deno 1.37+ installed
- Supabase CLI installed
- Git
- Code editor (VS Code recommended)

### Local Setup

```bash
# Clone repository
git clone <repository-url>
cd dacong-api

# Install Supabase CLI
npm install -g supabase

# Start local Supabase
supabase start

# This will output:
# - API URL: http://localhost:54321
# - Anon key: eyJh...
# - Service role key: eyJh...
```

### Environment Setup

Create `.env.local`:

```bash
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=<anon-key-from-supabase-start>
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
FRONTEND_URL=http://localhost:3000
ENVIRONMENT=development
```

## Project Structure

```
dacong-api/
├── supabase/
│   ├── functions/              # Edge Functions
│   │   ├── _shared/           # Shared utilities
│   │   │   ├── dto/           # Data Transfer Objects
│   │   │   ├── middleware/    # Middleware functions
│   │   │   ├── schemas/       # Zod validation schemas
│   │   │   ├── utils/         # Utility functions
│   │   │   └── ...
│   │   ├── auth-login/        # Auth functions
│   │   ├── auth-register/
│   │   ├── favorites-add/     # Favorites functions
│   │   ├── admin-users-list/  # Admin functions
│   │   └── tests/             # Test files
│   └── migrations/            # Database migrations
│       ├── 001_initial_schema.sql
│       ├── 20260419000001_create_audit_logs.sql
│       └── 20260419000002_create_user_roles.sql
├── docs/                      # Documentation
└── README.md
```

## Development Workflow

### 1. Create New Function

```bash
# Create function directory
mkdir supabase/functions/my-new-function

# Create index.ts
cat > supabase/functions/my-new-function/index.ts << 'EOF'
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  corsResponse,
  errorResponse,
  successResponse,
  validateMethod,
} from "../_shared/utils/http.ts";
import { initSentry, withSentry } from "../_shared/utils/sentry.ts";

initSentry({ functionName: "my-new-function" });

serve(
  withSentry(
    async (req) => {
      if (req.method === "OPTIONS") {
        return corsResponse();
      }

      validateMethod(req, ["GET"]);

      // Your logic here

      return successResponse({ message: "Success" });
    },
    {
      functionName: "my-new-function",
      captureErrors: true,
    }
  )
);
EOF
```

### 2. Test Function Locally

```bash
# Serve function locally
supabase functions serve my-new-function --env-file .env.local

# Test with curl
curl -X GET http://localhost:54321/functions/v1/my-new-function \
  -H "Authorization: Bearer <anon-key>"
```

### 3. Add Validation Schema

Create schema in `_shared/schemas/`:

```typescript
// _shared/schemas/my_schemas.ts
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

export const myInputSchema = z.object({
  field1: z.string().min(1),
  field2: z.number().int().positive(),
});

export type MyInput = z.infer<typeof myInputSchema>;
```

Use in function:

```typescript
import { myInputSchema, validateInput } from "../_shared/schemas/my_schemas.ts";

const body = await getRequestBody(req);
const input = validateInput(myInputSchema, body);
```

### 4. Add Tests

Create test file in `tests/`:

```typescript
// tests/my-function.test.ts
import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "http://localhost:54321";

Deno.test("My Function - Success case", async () => {
  const response = await fetch(`${SUPABASE_URL}/functions/v1/my-new-function`, {
    method: "GET",
    headers: {
      "Authorization": `Bearer ${Deno.env.get("SUPABASE_ANON_KEY")}`,
    },
  });

  const data = await response.json();
  assertEquals(response.status, 200);
  assertEquals(data.success, true);
});
```

Run tests:

```bash
deno test --allow-net --allow-env supabase/functions/tests/my-function.test.ts
```

### 5. Create Migration

```bash
# Create new migration
supabase migration new my_feature

# Edit the generated file
# supabase/migrations/<timestamp>_my_feature.sql

# Apply migration locally
supabase db push
```

## Code Style Guide

### TypeScript/Deno Best Practices

```typescript
// ✅ Good: Explicit types for public APIs
export function processUser(user: User): ProcessedUser {
  return { ...user, processed: true };
}

// ❌ Bad: No types
export function processUser(user) {
  return { ...user, processed: true };
}

// ✅ Good: Immutable updates
const updated = { ...original, field: newValue };

// ❌ Bad: Mutation
original.field = newValue;

// ✅ Good: Proper error handling
try {
  const result = await riskyOperation();
  return successResponse(result);
} catch (error) {
  captureException(error);
  return errorResponse("Operation failed", 500);
}

// ❌ Bad: Silent failures
const result = await riskyOperation().catch(() => null);
```

### Naming Conventions

- Functions: `camelCase` (e.g., `getUserProfile`)
- Types/Interfaces: `PascalCase` (e.g., `UserProfile`)
- Constants: `UPPER_SNAKE_CASE` (e.g., `MAX_RETRIES`)
- Files: `kebab-case` (e.g., `user-profile.ts`)

### File Organization

- Keep files under 400 lines
- One main export per file
- Group related functions in modules
- Use barrel exports (`index.ts`) for public APIs

## Database Development

### Creating Tables

```sql
-- Always include:
-- 1. UUID primary key
-- 2. Timestamps
-- 3. RLS policies
-- 4. Indexes
-- 5. Comments

CREATE TABLE my_table (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE my_table ENABLE ROW LEVEL SECURITY;

-- Add policies
CREATE POLICY "Users can view own data"
  ON my_table FOR SELECT
  USING (auth.uid() = user_id);

-- Add indexes
CREATE INDEX idx_my_table_user_id ON my_table(user_id);

-- Add comments
COMMENT ON TABLE my_table IS 'Description of table';
```

### Querying Data

```typescript
// ✅ Good: Type-safe queries
const { data, error } = await supabase
  .from("my_table")
  .select("id, data")
  .eq("user_id", userId)
  .single();

if (error) {
  throw new Error(error.message);
}

// ✅ Good: Pagination
const { data, count } = await supabase
  .from("my_table")
  .select("*", { count: "exact" })
  .range(offset, offset + limit - 1);

// ✅ Good: Filtering
const { data } = await supabase
  .from("my_table")
  .select("*")
  .or("status.eq.active,status.eq.pending")
  .order("created_at", { ascending: false });
```

## Testing

### Unit Tests

```typescript
// Test pure functions
Deno.test("formatUser - formats correctly", () => {
  const user = { firstName: "John", lastName: "Doe" };
  const result = formatUser(user);
  assertEquals(result, "John Doe");
});
```

### Integration Tests

```typescript
// Test API endpoints
Deno.test("POST /auth-login - valid credentials", async () => {
  const response = await fetch(`${SUPABASE_URL}/functions/v1/auth-login`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${SUPABASE_ANON_KEY}`,
    },
    body: JSON.stringify({
      email: "test@example.com",
      password: "password",
    }),
  });

  assertEquals(response.status, 200);
  const data = await response.json();
  assertExists(data.data.session.access_token);
});
```

### Test Coverage

```bash
# Run with coverage
deno test --allow-net --allow-env --coverage=coverage supabase/functions/tests/

# Generate report
deno coverage coverage --lcov > coverage.lcov

# View HTML report
deno coverage coverage --html
```

## Debugging

### Local Debugging

```typescript
// Add debug logging
if (Deno.env.get("ENVIRONMENT") === "development") {
  console.log("Debug:", { user, data });
}

// Use Deno debugger
// Run with: deno run --inspect-brk ...
debugger;
```

### Remote Debugging

```bash
# View function logs
supabase functions logs my-function --follow

# View database logs
supabase db logs --follow
```

## Performance Optimization

### Database Queries

```typescript
// ✅ Good: Select only needed fields
.select("id, name, email")

// ❌ Bad: Select all fields
.select("*")

// ✅ Good: Use indexes
.eq("indexed_field", value)

// ❌ Bad: Filter on non-indexed field
.ilike("non_indexed_field", "%value%")
```

### Function Performance

```typescript
// Measure execution time
const start = Date.now();
await operation();
const duration = Date.now() - start;

if (duration > 1000) {
  console.warn(`Slow operation: ${duration}ms`);
}
```

## Common Patterns

### Authentication Pattern

```typescript
const authHeader = req.headers.get("Authorization");
if (!authHeader) {
  return errorResponse("Missing authorization header", 401);
}

const supabase = createClient(supabaseUrl, supabaseKey, {
  global: { headers: { Authorization: authHeader } },
});

const { data: { user }, error } = await supabase.auth.getUser();
if (error || !user) {
  return errorResponse("Unauthorized", 401);
}
```

### Pagination Pattern

```typescript
const params = getQueryParams(req);
const page = parseInt(params.get("page") || "1");
const limit = Math.min(parseInt(params.get("limit") || "20"), 100);
const offset = (page - 1) * limit;

const { data, count } = await supabase
  .from("table")
  .select("*", { count: "exact" })
  .range(offset, offset + limit - 1);

return successResponse(data, {
  total: count || 0,
  page,
  limit,
  total_pages: Math.ceil((count || 0) / limit),
});
```

## Git Workflow

```bash
# Create feature branch
git checkout -b feature/my-feature

# Make changes and commit
git add .
git commit -m "feat: add my feature"

# Push and create PR
git push origin feature/my-feature
```

### Commit Message Format

```
<type>: <description>

Types:
- feat: New feature
- fix: Bug fix
- refactor: Code refactoring
- docs: Documentation
- test: Tests
- chore: Maintenance
```

## Resources

- [Supabase Docs](https://supabase.com/docs)
- [Deno Manual](https://deno.land/manual)
- [Zod Documentation](https://zod.dev)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
