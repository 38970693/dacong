/**
 * CSRF Middleware Unit Tests
 */

import { assertEquals, assertExists, assert } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  generateCsrfToken,
  validateCsrfToken,
  csrfMiddleware,
  generateCsrfCookieHeader,
} from "../_shared/middleware/csrf.ts";

// ============================================
// Token Generation Tests
// ============================================

Deno.test("generateCsrfToken creates valid token", () => {
  const token = generateCsrfToken();

  assertExists(token.token);
  assertExists(token.timestamp);
  assertEquals(token.token.length, 64); // 32 bytes * 2 (hex)
  assert(token.timestamp > 0);
  assert(token.timestamp <= Date.now());
});

Deno.test("generateCsrfToken creates unique tokens", () => {
  const token1 = generateCsrfToken();
  const token2 = generateCsrfToken();

  assert(token1.token !== token2.token);
  assert(token1.timestamp !== token2.timestamp);
});

// ============================================
// Cookie Header Generation Tests
// ============================================

Deno.test("generateCsrfCookieHeader creates valid cookie", () => {
  const token = generateCsrfToken();
  const cookieHeader = generateCsrfCookieHeader(token);

  assert(cookieHeader.includes("csrf_token="));
  assert(cookieHeader.includes("HttpOnly"));
  assert(cookieHeader.includes("SameSite=Strict"));
  assert(cookieHeader.includes("Max-Age=3600"));
  assert(cookieHeader.includes("Path=/"));
});

Deno.test("generateCsrfCookieHeader includes Secure in production", () => {
  const originalEnv = Deno.env.get("ENVIRONMENT");
  Deno.env.set("ENVIRONMENT", "production");

  const token = generateCsrfToken();
  const cookieHeader = generateCsrfCookieHeader(token);

  assert(cookieHeader.includes("Secure"));

  // Restore environment
  if (originalEnv) {
    Deno.env.set("ENVIRONMENT", originalEnv);
  } else {
    Deno.env.delete("ENVIRONMENT");
  }
});

// ============================================
// Token Validation Tests
// ============================================

Deno.test("validateCsrfToken rejects request without cookie", async () => {
  const req = new Request("https://example.com/api", {
    method: "POST",
    headers: {
      "X-CSRF-Token": "test-token",
    },
  });

  const response = await validateCsrfToken(req);

  assertExists(response);
  assertEquals(response!.status, 403);

  const body = await response!.json();
  assertEquals(body.error, "CSRF token missing in cookie");
});

Deno.test("validateCsrfToken rejects request without header", async () => {
  const token = generateCsrfToken();
  const encodedToken = `${token.token}:${token.timestamp}`;

  const req = new Request("https://example.com/api", {
    method: "POST",
    headers: {
      "Cookie": `csrf_token=${encodedToken}`,
    },
  });

  const response = await validateCsrfToken(req);

  assertExists(response);
  assertEquals(response!.status, 403);

  const body = await response!.json();
  assertEquals(body.error, "CSRF token missing in header");
});

Deno.test("validateCsrfToken rejects expired token", async () => {
  const expiredToken = {
    token: "a".repeat(64),
    timestamp: Date.now() - 7200000, // 2 hours ago
  };
  const encodedToken = `${expiredToken.token}:${expiredToken.timestamp}`;

  const req = new Request("https://example.com/api", {
    method: "POST",
    headers: {
      "Cookie": `csrf_token=${encodedToken}`,
      "X-CSRF-Token": encodedToken,
    },
  });

  const response = await validateCsrfToken(req);

  assertExists(response);
  assertEquals(response!.status, 403);

  const body = await response!.json();
  assertEquals(body.error, "CSRF token expired");
});

Deno.test("validateCsrfToken rejects mismatched tokens", async () => {
  const token1 = generateCsrfToken();
  const token2 = generateCsrfToken();

  const encodedToken1 = `${token1.token}:${token1.timestamp}`;
  const encodedToken2 = `${token2.token}:${token2.timestamp}`;

  const req = new Request("https://example.com/api", {
    method: "POST",
    headers: {
      "Cookie": `csrf_token=${encodedToken1}`,
      "X-CSRF-Token": encodedToken2,
    },
  });

  const response = await validateCsrfToken(req);

  assertExists(response);
  assertEquals(response!.status, 403);

  const body = await response!.json();
  assertEquals(body.error, "CSRF token mismatch");
});

Deno.test("validateCsrfToken accepts valid token", async () => {
  const token = generateCsrfToken();
  const encodedToken = `${token.token}:${token.timestamp}`;

  const req = new Request("https://example.com/api", {
    method: "POST",
    headers: {
      "Cookie": `csrf_token=${encodedToken}`,
      "X-CSRF-Token": encodedToken,
    },
  });

  const response = await validateCsrfToken(req);

  assertEquals(response, null); // No error
});

// ============================================
// Middleware Tests
// ============================================

Deno.test("csrfMiddleware skips GET requests", async () => {
  const req = new Request("https://example.com/api", {
    method: "GET",
  });

  const response = await csrfMiddleware(req);

  assertEquals(response, null); // No validation for GET
});

Deno.test("csrfMiddleware validates POST requests", async () => {
  const req = new Request("https://example.com/api", {
    method: "POST",
  });

  const response = await csrfMiddleware(req);

  assertExists(response);
  assertEquals(response!.status, 403);
});

Deno.test("csrfMiddleware validates PUT requests", async () => {
  const req = new Request("https://example.com/api", {
    method: "PUT",
  });

  const response = await csrfMiddleware(req);

  assertExists(response);
  assertEquals(response!.status, 403);
});

Deno.test("csrfMiddleware validates DELETE requests", async () => {
  const req = new Request("https://example.com/api", {
    method: "DELETE",
  });

  const response = await csrfMiddleware(req);

  assertExists(response);
  assertEquals(response!.status, 403);
});

Deno.test("csrfMiddleware validates PATCH requests", async () => {
  const req = new Request("https://example.com/api", {
    method: "PATCH",
  });

  const response = await csrfMiddleware(req);

  assertExists(response);
  assertEquals(response!.status, 403);
});

// ============================================
// Edge Cases
// ============================================

Deno.test("validateCsrfToken handles malformed cookie token", async () => {
  const req = new Request("https://example.com/api", {
    method: "POST",
    headers: {
      "Cookie": "csrf_token=invalid-format",
      "X-CSRF-Token": "invalid-format",
    },
  });

  const response = await validateCsrfToken(req);

  assertExists(response);
  assertEquals(response!.status, 403);
});

Deno.test("validateCsrfToken handles multiple cookies", async () => {
  const token = generateCsrfToken();
  const encodedToken = `${token.token}:${token.timestamp}`;

  const req = new Request("https://example.com/api", {
    method: "POST",
    headers: {
      "Cookie": `session=abc123; csrf_token=${encodedToken}; other=xyz`,
      "X-CSRF-Token": encodedToken,
    },
  });

  const response = await validateCsrfToken(req);

  assertEquals(response, null); // Should find csrf_token among multiple cookies
});

Deno.test("validateCsrfToken handles token at expiry boundary", async () => {
  // Token that expires in exactly 1 hour
  const token = {
    token: "a".repeat(64),
    timestamp: Date.now() - 3599000, // 59 minutes 59 seconds ago
  };
  const encodedToken = `${token.token}:${token.timestamp}`;

  const req = new Request("https://example.com/api", {
    method: "POST",
    headers: {
      "Cookie": `csrf_token=${encodedToken}`,
      "X-CSRF-Token": encodedToken,
    },
  });

  const response = await validateCsrfToken(req);

  assertEquals(response, null); // Should still be valid
});

// ============================================
// Security Tests
// ============================================

Deno.test("token generation uses cryptographically secure random", () => {
  const tokens = new Set();
  const iterations = 1000;

  for (let i = 0; i < iterations; i++) {
    const token = generateCsrfToken();
    tokens.add(token.token);
  }

  // All tokens should be unique
  assertEquals(tokens.size, iterations);
});

Deno.test("token comparison is constant-time safe", async () => {
  const token = generateCsrfToken();
  const encodedToken = `${token.token}:${token.timestamp}`;

  // Create a token that differs only in the last character
  const similarToken = encodedToken.slice(0, -1) + "x";

  const req1 = new Request("https://example.com/api", {
    method: "POST",
    headers: {
      "Cookie": `csrf_token=${encodedToken}`,
      "X-CSRF-Token": similarToken,
    },
  });

  const start1 = performance.now();
  await validateCsrfToken(req1);
  const time1 = performance.now() - start1;

  // Create a completely different token
  const differentToken = "z".repeat(encodedToken.length);

  const req2 = new Request("https://example.com/api", {
    method: "POST",
    headers: {
      "Cookie": `csrf_token=${encodedToken}`,
      "X-CSRF-Token": differentToken,
    },
  });

  const start2 = performance.now();
  await validateCsrfToken(req2);
  const time2 = performance.now() - start2;

  // Times should be similar (within 50% variance)
  // This is a basic check; true constant-time verification requires more sophisticated testing
  const ratio = Math.max(time1, time2) / Math.min(time1, time2);
  assert(ratio < 1.5, `Time ratio ${ratio} suggests non-constant-time comparison`);
});
