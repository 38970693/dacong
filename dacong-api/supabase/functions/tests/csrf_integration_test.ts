/**
 * CSRF Protection Integration Tests
 *
 * Tests the complete CSRF protection flow from token generation to validation
 */

import { assertEquals, assertExists, assert } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "http://localhost:54321";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") || "";
const API_BASE_URL = `${SUPABASE_URL}/functions/v1`;

// ============================================
// Helper Functions
// ============================================

async function getCsrfToken(accessToken?: string): Promise<{ token: string; cookie: string }> {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };

  if (accessToken) {
    headers["Authorization"] = `Bearer ${accessToken}`;
  }

  const response = await fetch(`${API_BASE_URL}/csrf-token`, {
    method: "GET",
    headers,
  });

  assertEquals(response.status, 200);

  const data = await response.json();
  const token = data.data.csrf_token;
  const cookie = response.headers.get("set-cookie") || "";

  return { token, cookie };
}

async function registerTestUser(): Promise<{ email: string; password: string; accessToken: string }> {
  const email = `test-${Date.now()}@example.com`;
  const password = "Test123!@#";
  const username = `testuser${Date.now()}`;

  const response = await fetch(`${API_BASE_URL}/auth-register`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      email,
      password,
      username,
    }),
  });

  const data = await response.json();

  // For testing, we'll use the Supabase client to get the access token
  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  const { data: authData } = await supabase.auth.signInWithPassword({
    email,
    password,
  });

  return {
    email,
    password,
    accessToken: authData?.session?.access_token || "",
  };
}

// ============================================
// Token Generation Tests
// ============================================

Deno.test("GET /csrf-token returns valid token for anonymous user", async () => {
  const { token, cookie } = await getCsrfToken();

  assertExists(token);
  assert(token.length > 0);
  assert(cookie.includes("csrf_token="));
  assert(cookie.includes("HttpOnly"));
  assert(cookie.includes("SameSite=Strict"));
});

Deno.test("GET /csrf-token returns valid token for authenticated user", async () => {
  const { accessToken } = await registerTestUser();
  const { token, cookie } = await getCsrfToken(accessToken);

  assertExists(token);
  assert(token.length > 0);
  assert(cookie.includes("csrf_token="));
});

Deno.test("POST /csrf-token refreshes token", async () => {
  const { accessToken } = await registerTestUser();
  const { token: token1 } = await getCsrfToken(accessToken);

  // Wait a bit to ensure different timestamp
  await new Promise(resolve => setTimeout(resolve, 100));

  const response = await fetch(`${API_BASE_URL}/csrf-token`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
  });

  assertEquals(response.status, 200);

  const data = await response.json();
  const token2 = data.data.csrf_token;

  assert(token1 !== token2, "Refreshed token should be different");
});

// ============================================
// Protected Endpoint Tests
// ============================================

Deno.test("POST request without CSRF token is rejected", async () => {
  const { accessToken } = await registerTestUser();

  const response = await fetch(`${API_BASE_URL}/auth-logout`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
  });

  assertEquals(response.status, 403);

  const data = await response.json();
  assert(data.error.includes("CSRF"));
});

Deno.test("POST request with valid CSRF token succeeds", async () => {
  const { accessToken } = await registerTestUser();
  const { token, cookie } = await getCsrfToken(accessToken);

  const response = await fetch(`${API_BASE_URL}/auth-logout`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
      "X-CSRF-Token": token,
      "Cookie": cookie,
    },
  });

  // Should succeed (200) or fail for other reasons (not 403)
  assert(response.status !== 403, "Should not fail CSRF validation");
});

Deno.test("POST request with mismatched CSRF tokens is rejected", async () => {
  const { accessToken } = await registerTestUser();
  const { token: token1 } = await getCsrfToken(accessToken);
  const { cookie: cookie2 } = await getCsrfToken(accessToken);

  const response = await fetch(`${API_BASE_URL}/auth-logout`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
      "X-CSRF-Token": token1,
      "Cookie": cookie2,
    },
  });

  assertEquals(response.status, 403);

  const data = await response.json();
  assertEquals(data.error, "CSRF token mismatch");
});

Deno.test("GET request does not require CSRF token", async () => {
  const { accessToken } = await registerTestUser();

  const response = await fetch(`${API_BASE_URL}/admin-users-list`, {
    method: "GET",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
  });

  // Should not fail with 403 CSRF error (may fail with 401/403 for other reasons)
  if (response.status === 403) {
    const data = await response.json();
    assert(!data.error.includes("CSRF"), "GET request should not require CSRF token");
  }
});

// ============================================
// Token Expiry Tests
// ============================================

Deno.test("Expired CSRF token is rejected", async () => {
  const { accessToken } = await registerTestUser();

  // Create an expired token (2 hours old)
  const expiredTimestamp = Date.now() - 7200000;
  const expiredToken = `${"a".repeat(64)}:${expiredTimestamp}`;

  const response = await fetch(`${API_BASE_URL}/auth-logout`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
      "X-CSRF-Token": expiredToken,
      "Cookie": `csrf_token=${expiredToken}`,
    },
  });

  assertEquals(response.status, 403);

  const data = await response.json();
  assertEquals(data.error, "CSRF token expired");
});

// ============================================
// Admin Endpoint Tests
// ============================================

Deno.test("Admin endpoint requires CSRF token", async () => {
  const { accessToken } = await registerTestUser();

  const response = await fetch(`${API_BASE_URL}/admin-batch-approve`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      content_ids: ["00000000-0000-0000-0000-000000000000"],
      status: "approved",
    }),
  });

  assertEquals(response.status, 403);

  const data = await response.json();
  assert(data.error.includes("CSRF") || data.error.includes("Unauthorized"));
});

Deno.test("Admin endpoint with valid CSRF token processes request", async () => {
  const { accessToken } = await registerTestUser();
  const { token, cookie } = await getCsrfToken(accessToken);

  const response = await fetch(`${API_BASE_URL}/admin-batch-approve`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
      "X-CSRF-Token": token,
      "Cookie": cookie,
    },
    body: JSON.stringify({
      content_ids: ["00000000-0000-0000-0000-000000000000"],
      status: "approved",
    }),
  });

  // Should not fail with CSRF error (may fail with auth/permission error)
  if (response.status === 403) {
    const data = await response.json();
    assert(!data.error.includes("CSRF"), "Should not fail CSRF validation");
  }
});

// ============================================
// Token Cleanup Tests
// ============================================

Deno.test("DELETE /csrf-token clears user tokens", async () => {
  const { accessToken } = await registerTestUser();
  const { token: token1 } = await getCsrfToken(accessToken);

  // Clear tokens
  const deleteResponse = await fetch(`${API_BASE_URL}/csrf-token`, {
    method: "DELETE",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
  });

  assertEquals(deleteResponse.status, 200);

  // Get new token - should be different
  const { token: token2 } = await getCsrfToken(accessToken);
  assert(token1 !== token2, "New token should be generated after clearing");
});

// ============================================
// Database Integration Tests
// ============================================

Deno.test("CSRF token is stored in database for authenticated users", async () => {
  const { accessToken } = await registerTestUser();
  await getCsrfToken(accessToken);

  // Verify token exists in database
  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: {
      headers: { Authorization: `Bearer ${accessToken}` },
    },
  });

  const { data: tokens } = await supabase
    .from("csrf_tokens")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(1);

  assertExists(tokens);
  assert(tokens.length > 0, "Token should be stored in database");
});

Deno.test("Database validates token ownership", async () => {
  const { accessToken: user1Token } = await registerTestUser();
  const { accessToken: user2Token } = await registerTestUser();

  // Get token for user 1
  const { token: user1CsrfToken, cookie: user1Cookie } = await getCsrfToken(user1Token);

  // Try to use user 1's token with user 2's session
  const response = await fetch(`${API_BASE_URL}/auth-logout`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${user2Token}`,
      "Content-Type": "application/json",
      "X-CSRF-Token": user1CsrfToken,
      "Cookie": user1Cookie,
    },
  });

  assertEquals(response.status, 403);

  const data = await response.json();
  assert(data.error.includes("CSRF") || data.error.includes("Invalid"));
});

// ============================================
// Performance Tests
// ============================================

Deno.test("CSRF validation has acceptable performance", async () => {
  const { accessToken } = await registerTestUser();
  const { token, cookie } = await getCsrfToken(accessToken);

  const iterations = 100;
  const start = performance.now();

  for (let i = 0; i < iterations; i++) {
    await fetch(`${API_BASE_URL}/auth-logout`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
        "X-CSRF-Token": token,
        "Cookie": cookie,
      },
    });
  }

  const end = performance.now();
  const avgTime = (end - start) / iterations;

  console.log(`Average CSRF validation time: ${avgTime.toFixed(2)}ms`);
  assert(avgTime < 100, "CSRF validation should be fast (<100ms per request)");
});

// ============================================
// Edge Cases
// ============================================

Deno.test("Multiple concurrent requests with same token succeed", async () => {
  const { accessToken } = await registerTestUser();
  const { token, cookie } = await getCsrfToken(accessToken);

  const requests = Array(10).fill(null).map(() =>
    fetch(`${API_BASE_URL}/auth-logout`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
        "X-CSRF-Token": token,
        "Cookie": cookie,
      },
    })
  );

  const responses = await Promise.all(requests);

  // All should not fail with CSRF error
  for (const response of responses) {
    if (response.status === 403) {
      const data = await response.json();
      assert(!data.error.includes("CSRF"), "Concurrent requests should not fail CSRF validation");
    }
  }
});

Deno.test("Token refresh during active session works correctly", async () => {
  const { accessToken } = await registerTestUser();
  const { token: token1, cookie: cookie1 } = await getCsrfToken(accessToken);

  // Make a request with token1
  const response1 = await fetch(`${API_BASE_URL}/auth-logout`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
      "X-CSRF-Token": token1,
      "Cookie": cookie1,
    },
  });

  assert(response1.status !== 403 || !(await response1.json()).error.includes("CSRF"));

  // Refresh token
  const { token: token2, cookie: cookie2 } = await getCsrfToken(accessToken);

  // Make a request with token2
  const response2 = await fetch(`${API_BASE_URL}/auth-logout`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
      "X-CSRF-Token": token2,
      "Cookie": cookie2,
    },
  });

  assert(response2.status !== 403 || !(await response2.json()).error.includes("CSRF"));
});
