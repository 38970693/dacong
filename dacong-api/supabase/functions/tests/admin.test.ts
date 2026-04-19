/**
 * Admin Functions Test Suite
 * 管理功能测试
 */

import { assertEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "http://localhost:54321";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") || "";

let adminToken: string;
let testUserId: string;

async function getAdminToken(): Promise<string> {
  if (adminToken) return adminToken;

  const response = await fetch(`${SUPABASE_URL}/functions/v1/auth-login`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${SUPABASE_ANON_KEY}`,
    },
    body: JSON.stringify({
      email: Deno.env.get("TEST_ADMIN_EMAIL"),
      password: Deno.env.get("TEST_ADMIN_PASSWORD"),
    }),
  });

  const data = await response.json();
  adminToken = data.data.session.access_token;
  return adminToken;
}

Deno.test("Admin - Get users list", async () => {
  const token = await getAdminToken();

  const response = await fetch(
    `${SUPABASE_URL}/functions/v1/admin-users-list?page=1&limit=20`,
    {
      method: "GET",
      headers: {
        "Authorization": `Bearer ${token}`,
      },
    }
  );

  const data = await response.json();
  assertEquals(response.status, 200);
  assertEquals(data.success, true);
  assertExists(data.data);
  assertExists(data.meta.total);
});

Deno.test("Admin - Ban user", async () => {
  const token = await getAdminToken();

  const response = await fetch(`${SUPABASE_URL}/functions/v1/admin-users-ban`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${token}`,
    },
    body: JSON.stringify({
      user_id: testUserId,
      reason: "Test ban",
      duration_days: 7,
    }),
  });

  const data = await response.json();
  assertEquals(response.status, 200);
  assertEquals(data.success, true);
});

Deno.test("Admin - Unban user", async () => {
  const token = await getAdminToken();

  const response = await fetch(`${SUPABASE_URL}/functions/v1/admin-users-unban`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${token}`,
    },
    body: JSON.stringify({
      user_id: testUserId,
    }),
  });

  const data = await response.json();
  assertEquals(response.status, 200);
  assertEquals(data.success, true);
});

Deno.test("Admin - Get audit logs", async () => {
  const token = await getAdminToken();

  const response = await fetch(
    `${SUPABASE_URL}/functions/v1/admin-audit-logs?page=1&limit=50`,
    {
      method: "GET",
      headers: {
        "Authorization": `Bearer ${token}`,
      },
    }
  );

  const data = await response.json();
  assertEquals(response.status, 200);
  assertEquals(data.success, true);
  assertExists(data.data);
});

Deno.test("Admin - Get stats", async () => {
  const token = await getAdminToken();

  const response = await fetch(`${SUPABASE_URL}/functions/v1/admin-stats`, {
    method: "GET",
    headers: {
      "Authorization": `Bearer ${token}`,
    },
  });

  const data = await response.json();
  assertEquals(response.status, 200);
  assertEquals(data.success, true);
  assertExists(data.data.users);
  assertExists(data.data.content);
  assertExists(data.data.engagement);
});

Deno.test("Admin - Batch approve content", async () => {
  const token = await getAdminToken();

  const response = await fetch(`${SUPABASE_URL}/functions/v1/admin-batch-approve`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${token}`,
    },
    body: JSON.stringify({
      content_ids: ["test-id-1", "test-id-2"],
      status: "approved",
    }),
  });

  const data = await response.json();
  assertEquals(data.success, true);
});

Deno.test("Admin - Non-admin access denied", async () => {
  const response = await fetch(`${SUPABASE_URL}/functions/v1/admin-users-list`, {
    method: "GET",
    headers: {
      "Authorization": `Bearer invalid-token`,
    },
  });

  assertEquals(response.status, 401);
});
