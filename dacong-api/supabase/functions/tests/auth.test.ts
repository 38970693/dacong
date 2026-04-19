/**
 * Auth Functions Test Suite
 * 认证功能测试
 */

import { assertEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "http://localhost:54321";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") || "";

const testEmail = `test-${Date.now()}@example.com`;
const testPassword = "TestPassword123!";
const testUsername = `testuser${Date.now()}`;

Deno.test("Auth - Register new user", async () => {
  const response = await fetch(`${SUPABASE_URL}/functions/v1/auth-register`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${SUPABASE_ANON_KEY}`,
    },
    body: JSON.stringify({
      email: testEmail,
      password: testPassword,
      username: testUsername,
    }),
  });

  const data = await response.json();
  assertEquals(response.status, 200);
  assertEquals(data.success, true);
  assertExists(data.data.user.id);
});

Deno.test("Auth - Register with duplicate username", async () => {
  const response = await fetch(`${SUPABASE_URL}/functions/v1/auth-register`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${SUPABASE_ANON_KEY}`,
    },
    body: JSON.stringify({
      email: `another-${Date.now()}@example.com`,
      password: testPassword,
      username: testUsername,
    }),
  });

  const data = await response.json();
  assertEquals(response.status, 400);
  assertEquals(data.success, false);
});

Deno.test("Auth - Login with valid credentials", async () => {
  const response = await fetch(`${SUPABASE_URL}/functions/v1/auth-login`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${SUPABASE_ANON_KEY}`,
    },
    body: JSON.stringify({
      email: testEmail,
      password: testPassword,
    }),
  });

  const data = await response.json();
  assertEquals(response.status, 200);
  assertEquals(data.success, true);
  assertExists(data.data.session.access_token);
  assertExists(data.data.session.refresh_token);
});

Deno.test("Auth - Login with invalid credentials", async () => {
  const response = await fetch(`${SUPABASE_URL}/functions/v1/auth-login`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${SUPABASE_ANON_KEY}`,
    },
    body: JSON.stringify({
      email: testEmail,
      password: "WrongPassword123!",
    }),
  });

  const data = await response.json();
  assertEquals(response.status, 401);
  assertEquals(data.success, false);
});

Deno.test("Auth - Refresh token", async () => {
  const loginResponse = await fetch(`${SUPABASE_URL}/functions/v1/auth-login`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${SUPABASE_ANON_KEY}`,
    },
    body: JSON.stringify({
      email: testEmail,
      password: testPassword,
    }),
  });

  const loginData = await loginResponse.json();
  const refreshToken = loginData.data.session.refresh_token;

  const response = await fetch(`${SUPABASE_URL}/functions/v1/auth-refresh`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${SUPABASE_ANON_KEY}`,
    },
    body: JSON.stringify({
      refresh_token: refreshToken,
    }),
  });

  const data = await response.json();
  assertEquals(response.status, 200);
  assertEquals(data.success, true);
  assertExists(data.data.session.access_token);
});

Deno.test("Auth - Logout", async () => {
  const loginResponse = await fetch(`${SUPABASE_URL}/functions/v1/auth-login`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${SUPABASE_ANON_KEY}`,
    },
    body: JSON.stringify({
      email: testEmail,
      password: testPassword,
    }),
  });

  const loginData = await loginResponse.json();
  const accessToken = loginData.data.session.access_token;

  const response = await fetch(`${SUPABASE_URL}/functions/v1/auth-logout`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${accessToken}`,
    },
  });

  const data = await response.json();
  assertEquals(response.status, 200);
  assertEquals(data.success, true);
});

Deno.test("Auth - Request password reset", async () => {
  const response = await fetch(`${SUPABASE_URL}/functions/v1/auth-reset-password`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${SUPABASE_ANON_KEY}`,
    },
    body: JSON.stringify({
      email: testEmail,
    }),
  });

  const data = await response.json();
  assertEquals(response.status, 200);
  assertEquals(data.success, true);
});
