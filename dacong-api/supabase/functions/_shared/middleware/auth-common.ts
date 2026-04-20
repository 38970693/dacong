/**
 * 通用认证中间件
 *
 * 验证用户身份和权限
 */

import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import { devMode } from '../config/dev-mode.ts';

export interface AuthUser {
  id: string;
  email: string;
  role?: string;
}

/**
 * 认证中间件
 *
 * @param req - HTTP 请求对象
 * @param supabase - Supabase 客户端
 * @returns 验证成功返回用户信息，失败返回错误响应
 */
export async function authMiddleware(
  req: Request,
  supabase: SupabaseClient
): Promise<{ user: AuthUser } | Response> {
  // 开发模式下可以禁用认证验证
  if (!devMode.enableAuth) {
    // 返回模拟用户
    return {
      user: {
        id: 'dev-user-id',
        email: 'dev@example.com',
        role: 'admin',
      },
    };
  }

  // 从 Authorization header 获取 token
  const authHeader = req.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response(
      JSON.stringify({ error: 'Missing or invalid authorization header' }),
      {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }

  const token = authHeader.substring(7);

  try {
    // 验证 token
    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired token' }),
        {
          status: 401,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }

    return {
      user: {
        id: user.id,
        email: user.email || '',
        role: user.user_metadata?.role,
      },
    };
  } catch (err) {
    console.error('Authentication error:', err);
    return new Response(
      JSON.stringify({ error: 'Authentication failed' }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
}

/**
 * 可选认证中间件（不强制要求登录）
 */
export async function optionalAuthMiddleware(
  req: Request,
  supabase: SupabaseClient
): Promise<{ user: AuthUser | null }> {
  // 开发模式下可以禁用认证验证
  if (!devMode.enableAuth) {
    return { user: null };
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return { user: null };
  }

  const token = authHeader.substring(7);

  try {
    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error || !user) {
      return { user: null };
    }

    return {
      user: {
        id: user.id,
        email: user.email || '',
        role: user.user_metadata?.role,
      },
    };
  } catch {
    return { user: null };
  }
}
