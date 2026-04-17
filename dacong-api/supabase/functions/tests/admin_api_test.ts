import { assertEquals, assertExists } from 'https://deno.land/std@0.168.0/testing/asserts.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

Deno.test('Admin Content Management API', async (t) => {
  const supabase = createClient(supabaseUrl, supabaseKey);

  // 创建测试管理员
  let adminToken: string;
  let testContentId: string;

  await t.step('Setup: Create test admin user', async () => {
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email: 'test-admin@example.com',
      password: 'test-password-123',
    });

    assertExists(authData.user);
    adminToken = authData.session?.access_token ?? '';

    // 添加到管理员表
    const { error: adminError } = await supabase
      .from('admin_users')
      .insert({
        id: authData.user!.id,
        email: 'test-admin@example.com',
        role: 'admin',
        is_active: true,
      });

    assertEquals(adminError, null);
  });

  await t.step('Setup: Create test content', async () => {
    const { data, error } = await supabase
      .from('posts')
      .insert({
        title: 'Test Post',
        content: 'Test content',
        moderation_status: 'pending',
      })
      .select()
      .single();

    assertExists(data);
    testContentId = data.id;
  });

  await t.step('GET: Should fetch content list', async () => {
    const response = await fetch(
      `${supabaseUrl}/functions/v1/admin-content-management?status=pending&page=1&limit=10`,
      {
        headers: {
          Authorization: `Bearer ${adminToken}`,
        },
      }
    );

    assertEquals(response.status, 200);
    const data = await response.json();
    assertExists(data.data);
    assertExists(data.data.items);
  });

  await t.step('POST: Should approve content', async () => {
    const response = await fetch(
      `${supabaseUrl}/functions/v1/admin-content-management`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${adminToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          action: 'approve',
          content_ids: [testContentId],
        }),
      }
    );

    assertEquals(response.status, 200);
    const data = await response.json();
    assertExists(data.data);
  });

  await t.step('PUT: Should edit content', async () => {
    const response = await fetch(
      `${supabaseUrl}/functions/v1/admin-content-management`,
      {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${adminToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          content_id: testContentId,
          title: 'Updated Title',
        }),
      }
    );

    assertEquals(response.status, 200);
  });

  await t.step('DELETE: Should delete content', async () => {
    const response = await fetch(
      `${supabaseUrl}/functions/v1/admin-content-management`,
      {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${adminToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          content_ids: [testContentId],
        }),
      }
    );

    assertEquals(response.status, 200);
  });

  await t.step('Cleanup: Remove test data', async () => {
    // 清理测试数据
    await supabase.from('admin_users').delete().eq('email', 'test-admin@example.com');
    await supabase.auth.admin.deleteUser(adminToken);
  });
});

Deno.test('Admin User Management API', async (t) => {
  const supabase = createClient(supabaseUrl, supabaseKey);

  let adminToken: string;
  let testUserId: string;

  await t.step('Setup: Create test admin and user', async () => {
    // 创建管理员
    const { data: adminData } = await supabase.auth.signUp({
      email: 'test-admin-2@example.com',
      password: 'test-password-123',
    });

    adminToken = adminData.session?.access_token ?? '';

    await supabase.from('admin_users').insert({
      id: adminData.user!.id,
      email: 'test-admin-2@example.com',
      role: 'admin',
      is_active: true,
    });

    // 创建测试用户
    const { data: userData } = await supabase.auth.signUp({
      email: 'test-user@example.com',
      password: 'test-password-123',
    });

    testUserId = userData.user!.id;
  });

  await t.step('GET: Should fetch user list', async () => {
    const response = await fetch(
      `${supabaseUrl}/functions/v1/admin-user-management?page=1&limit=10`,
      {
        headers: {
          Authorization: `Bearer ${adminToken}`,
        },
      }
    );

    assertEquals(response.status, 200);
    const data = await response.json();
    assertExists(data.data);
  });

  await t.step('GET: Should fetch user detail', async () => {
    const response = await fetch(
      `${supabaseUrl}/functions/v1/admin-user-management?user_id=${testUserId}`,
      {
        headers: {
          Authorization: `Bearer ${adminToken}`,
        },
      }
    );

    assertEquals(response.status, 200);
    const data = await response.json();
    assertExists(data.data.profile);
    assertExists(data.data.stats);
  });

  await t.step('POST: Should ban user', async () => {
    const response = await fetch(
      `${supabaseUrl}/functions/v1/admin-user-management`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${adminToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          action: 'ban',
          user_id: testUserId,
          reason: 'Test ban',
        }),
      }
    );

    assertEquals(response.status, 200);
  });

  await t.step('POST: Should unban user', async () => {
    const response = await fetch(
      `${supabaseUrl}/functions/v1/admin-user-management`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${adminToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          action: 'unban',
          user_id: testUserId,
        }),
      }
    );

    assertEquals(response.status, 200);
  });

  await t.step('Cleanup', async () => {
    await supabase.from('admin_users').delete().eq('email', 'test-admin-2@example.com');
    await supabase.auth.admin.deleteUser(testUserId);
  });
});

Deno.test('Admin Comment Moderation API', async (t) => {
  const supabase = createClient(supabaseUrl, supabaseKey);

  let adminToken: string;
  let testCommentId: string;

  await t.step('Setup', async () => {
    const { data: adminData } = await supabase.auth.signUp({
      email: 'test-admin-3@example.com',
      password: 'test-password-123',
    });

    adminToken = adminData.session?.access_token ?? '';

    await supabase.from('admin_users').insert({
      id: adminData.user!.id,
      email: 'test-admin-3@example.com',
      role: 'admin',
      is_active: true,
    });

    // 创建测试评论
    const { data: commentData } = await supabase
      .from('comments')
      .insert({
        content: 'Test comment',
        moderation_status: 'pending',
      })
      .select()
      .single();

    testCommentId = commentData.id;
  });

  await t.step('GET: Should fetch comment list', async () => {
    const response = await fetch(
      `${supabaseUrl}/functions/v1/admin-comment-moderation?page=1&limit=10&status=pending`,
      {
        headers: {
          Authorization: `Bearer ${adminToken}`,
        },
      }
    );

    assertEquals(response.status, 200);
    const data = await response.json();
    assertExists(data.data);
  });

  await t.step('POST: Should approve comment', async () => {
    const response = await fetch(
      `${supabaseUrl}/functions/v1/admin-comment-moderation`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${adminToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          action: 'approve',
          comment_ids: [testCommentId],
        }),
      }
    );

    assertEquals(response.status, 200);
  });

  await t.step('Cleanup', async () => {
    await supabase.from('comments').delete().eq('id', testCommentId);
    await supabase.from('admin_users').delete().eq('email', 'test-admin-3@example.com');
  });
});
