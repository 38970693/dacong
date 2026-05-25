/**
 * Admin Utilities
 * 管理端权限验证工具
 */
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

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
 * 检查用户是否为管理员
 * 检查 profiles 表的 role 字段是否为 'admin'
 * 开发模式下跳过权限检查
 */
export async function isAdmin(userId: string): Promise<boolean> {
  // 开发模式跳过检查
  if (process.env.NODE_ENV === 'development' && !supabaseKey) {
    return true;
  }

  const client = getSupabaseClient();
  if (!client) {
    // 无数据库连接时使用开发模式逻辑
    return process.env.NODE_ENV === 'development';
  }

  try {
    const { data: profile, error } = await client
      .from('profiles')
      .select('role')
      .eq('id', userId)
      .single();

    if (error || !profile) {
      return false;
    }

    return profile.role === 'admin';
  } catch (e) {
    console.error('Admin check failed:', e);
    return false;
  }
}

/**
 * 要求请求必须有管理员权限
 * 如果不是管理员，返回 403 错误
 * 返回管理员用户 ID
 */
export async function requireAdmin(
  request: NextRequest
): Promise<{ userId: string } | NextResponse> {
  // 获取 Authorization header
  const authHeader = request.headers.get('Authorization');
  let userId: string | null = null;

  const client = getSupabaseClient();

  // 从 Authorization header 获取用户
  if (authHeader?.startsWith('Bearer ') && client) {
    const token = authHeader.substring(7);
    try {
      const { data: { user } } = await client.auth.getUser(token);
      userId = user?.id ?? null;
    } catch (e) {
      console.error('Auth validation failed:', e);
    }
  }

  // 开发模式：尝试从查询参数获取 user_id
  if (!userId) {
    const url = new URL(request.url);
    const devUserId = url.searchParams.get('dev_user_id');
    if (devUserId && process.env.NODE_ENV === 'development') {
      userId = devUserId;
    }
  }

  // 如果没有用户，返回 401
  if (!userId) {
    return NextResponse.json(
      { success: false, error: 'Authentication required' },
      { status: 401 }
    );
  }

  // 检查是否为管理员
  const admin = await isAdmin(userId);
  if (!admin) {
    return NextResponse.json(
      { success: false, error: 'Admin access required' },
      { status: 403 }
    );
  }

  return { userId };
}