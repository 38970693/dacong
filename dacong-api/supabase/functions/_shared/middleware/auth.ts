/**
 * 管理员认证中间件
 * 验证管理员身份和权限
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

export interface AdminUser {
  id: string;
  email: string;
  role: 'admin' | 'moderator' | 'viewer';
  permissions: Record<string, boolean>;
  is_active: boolean;
}

export interface AuthContext {
  user: AdminUser;
  supabase: ReturnType<typeof createClient>;
}

/**
 * 验证管理员身份
 */
export async function requireAdmin(req: Request): Promise<AuthContext> {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    throw new Error('Missing authorization header');
  }

  const token = authHeader.replace('Bearer ', '');

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    {
      global: {
        headers: { Authorization: authHeader },
      },
    }
  );

  // 验证 JWT token
  const { data: { user }, error: authError } = await supabase.auth.getUser(token);

  if (authError || !user) {
    throw new Error('Invalid or expired token');
  }

  // 检查是否是管理员
  const { data: adminUser, error: adminError } = await supabase
    .from('admin_users')
    .select('*')
    .eq('id', user.id)
    .eq('is_active', true)
    .single();

  if (adminError || !adminUser) {
    throw new Error('User is not an admin');
  }

  return {
    user: adminUser as AdminUser,
    supabase,
  };
}

/**
 * 检查特定权限
 */
export function requirePermission(
  user: AdminUser,
  permission: string
): void {
  // admin 角色拥有所有权限
  if (user.role === 'admin') {
    return;
  }

  // viewer 角色只能查看
  if (user.role === 'viewer' && !permission.startsWith('view')) {
    throw new Error('Insufficient permissions');
  }

  // 检查自定义权限
  if (user.permissions[permission] !== true) {
    throw new Error(`Missing permission: ${permission}`);
  }
}

/**
 * 记录管理员操作日志
 */
export async function logAdminAction(
  supabase: ReturnType<typeof createClient>,
  adminId: string,
  action: string,
  targetType?: string,
  targetId?: string,
  details?: Record<string, unknown>,
  req?: Request
): Promise<void> {
  const ipAddress = req?.headers.get('x-forwarded-for') ||
                    req?.headers.get('x-real-ip') ||
                    'unknown';
  const userAgent = req?.headers.get('user-agent') || 'unknown';

  await supabase.from('admin_logs').insert({
    admin_id: adminId,
    action,
    target_type: targetType,
    target_id: targetId,
    details: details || {},
    ip_address: ipAddress,
    user_agent: userAgent,
  });
}

/**
 * 错误响应辅助函数
 */
export function errorResponse(message: string, status = 400): Response {
  return new Response(
    JSON.stringify({ error: message }),
    {
      status,
      headers: { 'Content-Type': 'application/json' },
    }
  );
}

/**
 * 成功响应辅助函数
 */
export function successResponse(data: unknown, status = 200): Response {
  return new Response(
    JSON.stringify({ data }),
    {
      status,
      headers: { 'Content-Type': 'application/json' },
    }
  );
}
