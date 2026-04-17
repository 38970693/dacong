import { assertEquals, assertExists } from "https://deno.land/std@0.168.0/testing/asserts.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

Deno.test("Submit Comment - Success", async () => {
  const supabase = createClient(supabaseUrl, supabaseKey);

  // 模拟认证用户
  const testUserId = "test-user-123";
  const testContentId = "test-content-123";

  const response = await supabase.functions.invoke("submit-comment", {
    body: {
      content_id: testContentId,
      content: "This is a test comment",
    },
  });

  assertEquals(response.status, 200);
  assertExists(response.data);
  assertEquals(response.data.success, true);
  assertExists(response.data.data.comment);
});

Deno.test("Submit Comment - Empty Content", async () => {
  const supabase = createClient(supabaseUrl, supabaseKey);

  const response = await supabase.functions.invoke("submit-comment", {
    body: {
      content_id: "test-content-123",
      content: "",
    },
  });

  assertEquals(response.status, 400);
  assertEquals(response.data.success, false);
});

Deno.test("Submit Comment - Too Long", async () => {
  const supabase = createClient(supabaseUrl, supabaseKey);

  const longContent = "a".repeat(2001);

  const response = await supabase.functions.invoke("submit-comment", {
    body: {
      content_id: "test-content-123",
      content: longContent,
    },
  });

  assertEquals(response.status, 400);
  assertEquals(response.data.success, false);
});

Deno.test("Get Comments - Success", async () => {
  const supabase = createClient(supabaseUrl, supabaseKey);

  const response = await supabase.functions.invoke("get-comments", {
    body: {
      content_id: "test-content-123",
      page: 1,
      limit: 20,
      sort: "latest",
    },
  });

  assertEquals(response.status, 200);
  assertExists(response.data);
  assertEquals(response.data.success, true);
  assertExists(response.data.data.comments);
  assertExists(response.data.data.pagination);
});

Deno.test("Like Comment - Success", async () => {
  const supabase = createClient(supabaseUrl, supabaseKey);

  const response = await supabase.functions.invoke("like-comment", {
    body: {
      comment_id: "test-comment-123",
      action: "like",
    },
  });

  assertEquals(response.status, 200);
  assertEquals(response.data.success, true);
});

Deno.test("Unlike Comment - Success", async () => {
  const supabase = createClient(supabaseUrl, supabaseKey);

  const response = await supabase.functions.invoke("like-comment", {
    body: {
      comment_id: "test-comment-123",
      action: "unlike",
    },
  });

  assertEquals(response.status, 200);
  assertEquals(response.data.success, true);
});

Deno.test("Report Comment - Success", async () => {
  const supabase = createClient(supabaseUrl, supabaseKey);

  const response = await supabase.functions.invoke("report-comment", {
    body: {
      comment_id: "test-comment-123",
      reason: "Spam",
    },
  });

  assertEquals(response.status, 200);
  assertEquals(response.data.success, true);
});
