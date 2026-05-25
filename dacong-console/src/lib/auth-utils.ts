/**
 * Auth Utilities
 * 评论系统权限验证工具
 */
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { NextRequest } from 'next/server';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

// 单例 Supabase 客户端
let supabase: SupabaseClient | null = null;

function getSupabaseClient(): SupabaseClient | null {
  if (!supabase && supabaseKey) {
    supabase = createClient(supabaseUrl, supabaseKey);
  }
  return supabase;
}

/**
 * 用户信息接口
 */
export interface CurrentUser {
  id: string;
  email?: string;
  username?: string;
}

/**
 * 从请求中获取当前用户
 * 支持多种认证方式：
 * 1. Authorization header (Bearer token)
 * 2. Cookie 中的 session
 * 3. 查询参数中的 user_id (仅用于开发)
 */
export async function getCurrentUser(
  request: NextRequest
): Promise<CurrentUser | null> {
  const client = getSupabaseClient();
  if (!client) {
    // 开发模式：尝试从查询参数获取 user_id
    const url = new URL(request.url);
    const devUserId = url.searchParams.get('dev_user_id');
    if (devUserId && process.env.NODE_ENV === 'development') {
      return { id: devUserId };
    }
    return null;
  }

  // 方式1: Authorization header
  const authHeader = request.headers.get('Authorization');
  if (authHeader?.startsWith('Bearer ')) {
    const token = authHeader.substring(7);
    try {
      const { data: { user }, error } = await client.auth.getUser(token);
      if (user && !error) {
        return {
          id: user.id,
          email: user.email,
        };
      }
    } catch (e) {
      console.error('Auth header validation failed:', e);
    }
  }

  // 方式2: Cookie 中的 session (Supabase SSR)
  try {
    const cookies = request.cookies;
    const accessToken = cookies.get('sb-access-token')?.value;
    if (accessToken) {
      const { data: { user }, error } = await client.auth.getUser(accessToken);
      if (user && !error) {
        return {
          id: user.id,
          email: user.email,
        };
      }
    }
  } catch (e) {
    console.error('Cookie validation failed:', e);
  }

  // 开发模式：尝试从查询参数获取 user_id
  const url = new URL(request.url);
  const devUserId = url.searchParams.get('dev_user_id');
  if (devUserId && process.env.NODE_ENV === 'development') {
    return { id: devUserId };
  }

  return null;
}

/**
 * 验证评论所有权
 * 检查评论是否属于指定用户
 */
export async function verifyCommentOwnership(
  commentId: string,
  userId: string
): Promise<{ isOwner: boolean; comment?: { user_id: string } }> {
  const client = getSupabaseClient();
  if (!client) {
    // 开发模式：跳过验证
    return { isOwner: true };
  }

  try {
    const { data: comment, error } = await client
      .from('comments')
      .select('user_id')
      .eq('id', commentId)
      .single();

    if (error || !comment) {
      return { isOwner: false };
    }

    return {
      isOwner: comment.user_id === userId,
      comment,
    };
  } catch (e) {
    console.error('Verify ownership failed:', e);
    return { isOwner: false };
  }
}

/**
 * 验证用户是否有权限执行操作
 */
export async function verifyPermission(
  action: 'create' | 'update' | 'delete',
  resourceType: 'comment',
  resourceId: string,
  userId: string
): Promise<{ allowed: boolean; reason?: string }> {
  const client = getSupabaseClient();
  if (!client) {
    // 开发模式：允许所有操作
    return { allowed: true };
  }

  switch (action) {
    case 'delete':
      // 删除：必须是评论作者
      const ownership = await verifyCommentOwnership(resourceId, userId);
      if (!ownership.isOwner) {
        return {
          allowed: false,
          reason: 'You can only delete your own comments',
        };
      }
      return { allowed: true };

    case 'update':
      // 更新：必须是评论作者
      const updateOwnership = await verifyCommentOwnership(resourceId, userId);
      if (!updateOwnership.isOwner) {
        return {
          allowed: false,
          reason: 'You can only edit your own comments',
        };
      }
      return { allowed: true };

    case 'create':
      // 创建：只需要用户已登录（userId 存在）
      if (!userId) {
        return {
          allowed: false,
          reason: 'Authentication required',
        };
      }
      return { allowed: true };

    default:
      return {
        allowed: false,
        reason: 'Unknown action',
      };
  }
}

/**
 * 创建统一的 API 响应
 */
export function apiResponse<T>(
  data: T,
  status: 200 | 201 = 200
): { success: true; data: T } {
  return { success: true, data };
}

/**
 * 创建统一的错误响应
 */
export function errorResponse(
  error: string,
  status: 400 | 401 | 403 | 404 | 500 = 400
): { success: false; error: string } {
  return { success: false, error };
}

/**
 * 获取用户 ID 辅助函数
 * 如果用户未登录且非开发模式，抛出 401 错误
 */
export async function requireAuth(
  request: NextRequest
): Promise<{ user: CurrentUser; userId: string }> {
  const user = await getCurrentUser(request);

  if (!user) {
    throw { status: 401, message: 'Authentication required' };
  }

  return {
    user,
    userId: user.id,
  };
}

/**
 * 获取用户 ID（可选）
 * 不会抛出错误，如果用户未登录返回 null
 */
export async function getOptionalUserId(
  request: NextRequest
): Promise<string | null> {
  const user = await getCurrentUser(request);
  return user?.id ?? null;
}

/**
 * 从数据库获取用户 profile
 */
export async function getUserProfile(userId: string): Promise<{
  username?: string;
  avatar?: string | null;
} | null> {
  const client = getSupabaseClient();
  if (!client) return null;

  try {
    const { data: profile, error } = await client
      .from('profiles')
      .select('username, avatar')
      .eq('id', userId)
      .single();

    if (error || !profile) {
      return null;
    }

    return {
      username: profile.username,
      avatar: profile.avatar,
    };
  } catch (e) {
    console.error('Get user profile failed:', e);
    return null;
  }
}