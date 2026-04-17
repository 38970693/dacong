import { assertEquals, assertExists } from 'https://deno.land/std@0.168.0/testing/asserts.ts';
import { requireAdmin, requirePermission, logAdminAction } from '../_shared/middleware/auth.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

Deno.test('Auth Middleware - requireAdmin', async (t) => {
  await t.step('Should reject request without auth header', async () => {
    const req = new Request('http://localhost', {
      method: 'GET',
    });

    try {
      await requireAdmin(req);
      throw new Error('Should have thrown');
    } catch (e) {
      assertEquals(e.message, 'Missing authorization header');
    }
  });

  await t.step('Should reject invalid token', async () => {
    const req = new Request('http://localhost', {
      method: 'GET',
      headers: {
        Authorization: 'Bearer invalid-token',
      },
    });

    try {
      await requireAdmin(req);
      throw new Error('Should have thrown');
    } catch (e) {
      assertEquals(e.message, 'Invalid or expired token');
    }
  });

  await t.step('Should reject non-admin user', async () => {
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 创建普通用户
    const { data: userData } = await supabase.auth.signUp({
      email: 'regular-user@example.com',
      password: 'test-password-123',
    });

    const token = userData.session?.access_token ?? '';

    const req = new Request('http://localhost', {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    try {
      await requireAdmin(req);
      throw new Error('Should have thrown');
    } catch (e) {
      assertEquals(e.message, 'User is not an admin');
    }

    // 清理
    await supabase.auth.admin.deleteUser(userData.user!.id);
  });

  await t.step('Should accept valid admin user', async () => {
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 创建管理员
    const { data: adminData } = await supabase.auth.signUp({
      email: 'admin-user@example.com',
      password: 'test-password-123',
    });

    await supabase.from('admin_users').insert({
      id: adminData.user!.id,
      email: 'admin-user@example.com',
      role: 'admin',
      is_active: true,
    });

    const token = adminData.session?.access_token ?? '';

    const req = new Request('http://localhost', {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    const context = await requireAdmin(req);
    assertExists(context.user);
    assertEquals(context.user.role, 'admin');

    // 清理
    await supabase.from('admin_users').delete().eq('id', adminData.user!.id);
    await supabase.auth.admin.deleteUser(adminData.user!.id);
  });
});

Deno.test('Auth Middleware - requirePermission', async (t) => {
  await t.step('Should allow admin role all permissions', () => {
    const adminUser = {
      id: 'test-id',
      email: 'admin@example.com',
      role: 'admin' as const,
      permissions: {},
      is_active: true,
    };

    // 不应该抛出异常
    requirePermission(adminUser, 'any_permission');
  });

  await t.step('Should restrict viewer role', () => {
    const viewerUser = {
      id: 'test-id',
      email: 'viewer@example.com',
      role: 'viewer' as const,
      permissions: {},
      is_active: true,
    };

    try {
      requirePermission(viewerUser, 'edit_content');
      throw new Error('Should have thrown');
    } catch (e) {
      assertEquals(e.message, 'Insufficient permissions');
    }
  });

  await t.step('Should check custom permissions', () => {
    const moderatorUser = {
      id: 'test-id',
      email: 'moderator@example.com',
      role: 'moderator' as const,
      permissions: {
        view_content: true,
        moderate_content: true,
      },
      is_active: true,
    };

    // 应该允许
    requirePermission(moderatorUser, 'view_content');
    requirePermission(moderatorUser, 'moderate_content');

    // 应该拒绝
    try {
      requirePermission(moderatorUser, 'delete_user');
      throw new Error('Should have thrown');
    } catch (e) {
      assertEquals(e.message, 'Missing permission: delete_user');
    }
  });
});

Deno.test('Auth Middleware - logAdminAction', async (t) => {
  await t.step('Should log admin action', async () => {
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 创建测试管理员
    const { data: adminData } = await supabase.auth.signUp({
      email: 'log-test-admin@example.com',
      password: 'test-password-123',
    });

    await supabase.from('admin_users').insert({
      id: adminData.user!.id,
      email: 'log-test-admin@example.com',
      role: 'admin',
      is_active: true,
    });

    const req = new Request('http://localhost', {
      method: 'POST',
      headers: {
        'x-forwarded-for': '127.0.0.1',
        'user-agent': 'Test Agent',
      },
    });

    await logAdminAction(
      supabase,
      adminData.user!.id,
      'test_action',
      'test_type',
      'test_id',
      { test: 'data' },
      req
    );

    // 验证日志已创建
    const { data: logs } = await supabase
      .from('admin_logs')
      .select('*')
      .eq('admin_id', adminData.user!.id)
      .eq('action', 'test_action');

    assertExists(logs);
    assertEquals(logs.length, 1);
    assertEquals(logs[0].target_type, 'test_type');
    assertEquals(logs[0].target_id, 'test_id');

    // 清理
    await supabase.from('admin_logs').delete().eq('admin_id', adminData.user!.id);
    await supabase.from('admin_users').delete().eq('id', adminData.user!.id);
    await supabase.auth.admin.deleteUser(adminData.user!.id);
  });
});
