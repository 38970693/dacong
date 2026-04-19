/**
 * Favorites Functions Test Suite
 * 收藏功能测试
 */

import { assertEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "http://localhost:54321";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") || "";

let accessToken: string;
let testContentId: string;

async function getAuthToken(): Promise<string> {
  if (accessToken) return accessToken;

  const response = await fetch(`${SUPABASE_URL}/functions/v1/auth-login`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${SUPABASE_ANON_KEY}`,
    },
    body: JSON.stringify({
      email: Deno.env.get("TEST_USER_EMAIL"),
      password: Deno.env.get("TEST_USER_PASSWORD"),
    }),
  });

  const data = await response.json();
  accessToken = data.data.session.access_token;
  return accessToken;
}

Deno.test("Favorites - Add favorite", async () => {
  const token = await getAuthToken();

  const response = await fetch(`${SUPABASE_URL}/functions/v1/favorites-add`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${token}`,
    },
    body: JSON.stringify({
      content_id: testContentId,
    }),
  });

  const data = await response.json();
  assertEquals(response.status, 200);
  assertEquals(data.success, true);
  assertExists(data.data.favorite_id);
});

Deno.test("Favorites - Add duplicate favorite", async () => {
  const token = await getAuthToken();

  const response = await fetch(`${SUPABASE_URL}/functions/v1/favorites-add`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${token}`,
    },
    body: JSON.stringify({
      content_id: testContentId,
    }),
  });

  const data = await response.json();
  assertEquals(response.status, 400);
  assertEquals(data.success, false);
});

Deno.test("Favorites - Check if favorited", async () => {
  const token = await getAuthToken();

  const response = await fetch(
    `${SUPABASE_URL}/functions/v1/favorites-check?content_id=${testContentId}`,
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
  assertEquals(data.data.is_favorited, true);
});

Deno.test("Favorites - Get favorites list", async () => {
  const token = await getAuthToken();

  const response = await fetch(
    `${SUPABASE_URL}/functions/v1/get-favorites?page=1&limit=20`,
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

Deno.test("Favorites - Remove favorite", async () => {
  const token = await getAuthToken();

  const response = await fetch(
    `${SUPABASE_URL}/functions/v1/favorites-remove?content_id=${testContentId}`,
    {
      method: "DELETE",
      headers: {
        "Authorization": `Bearer ${token}`,
      },
    }
  );

  const data = await response.json();
  assertEquals(response.status, 200);
  assertEquals(data.success, true);
});

Deno.test("Favorites - Check after removal", async () => {
  const token = await getAuthToken();

  const response = await fetch(
    `${SUPABASE_URL}/functions/v1/favorites-check?content_id=${testContentId}`,
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
  assertEquals(data.data.is_favorited, false);
});
