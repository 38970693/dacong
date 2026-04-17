/**
 * 管理后台 - 用户管理 API
 *
 * 功能：
 * - GET: 获取用户列表 / 用户详情
 * - POST: 封禁/解封用户
 * - DELETE: 删除用户
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import {
  requireAdmin,
  requirePermission,
  logAdminAction,
  errorResponse,
  successResponse,
} from '../_shared/middleware/auth.ts';
import { csrfMiddleware } from '../_shared/middleware/csrf.ts';

serve(async (req) => {
  // CORS 处理
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, content-type, x-csrf-token',
      },
    });
  }

  try {
    // CSRF 防护（仅对状态变更操作）
    if (['POST', 'DELETE'].includes(req.method)) {
      const csrfError = await csrfMiddleware(req);
      if (csrfError) return csrfError;
    }

    const { user, supabase } = await requireAdmin(req);
    const url = new URL(req.url);
    const method = req.method;

    // GET: 获取用户列表或详情
    if (method === 'GET') {
      requirePermission(user, 'view_users');

      const userId = url.searchParams.get('user_id');

      // 获取单个用户详情
      if (userId) {
        const { data: profile, error: profileError } = await supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();

        if (profileError) throw profileError;

        // 获取用户统计
        const { data: posts } = await supabase
          .from('posts')
          .select('id', { count: 'exact' })
          .eq('user_id', userId);

        const { data: comments } = await supabase
          .from('comments')
          .select('id', { count: 'exact' })
          .eq('user_id', userId);

        const { data: followers } = await supabase
          .from('follows')
          .select('id', { count: 'exact' })
          .eq('following_id', userId);

        const { data: following } = await supabase
          .from('follows')
          .select('id', { count: 'exact' })
          .eq('follower_id', userId);

        // 获取最近活动
        const { data: recentPosts } = await supabase
          .from('posts')
          .select('id, title, created_at')
          .eq('user_id', userId)
          .order('created_at', { ascending: false })
          .limit(5);

        const { data: recentComments } = await supabase
          .from('comments')
          .select('id, content, created_at, post_id')
          .eq('user_id', userId)
          .order('created_at', { ascending: false })
          .limit(5);

        return successResponse({
          profile,
          stats: {
            posts_count: posts?.length || 0,
            comments_count: comments?.length || 0,
            followers_count: followers?.length || 0,
            following_count: following?.length || 0,
          },
          recent_activity: {
            posts: recentPosts || [],
            comments: recentComments || [],
          },
        });
      }

      // 获取用户列表
      const page = parseInt(url.searchParams.get('page') || '1');
      const limit = parseInt(url.searchParams.get('limit') || '20');
      const search = url.searchParams.get('search') || '';
      const status = url.searchParams.get('status') || 'all';

      const offset = (page - 1) * limit;

      let query = supabase
        .from('profiles')
        .select('*', { count: 'exact' });

      // 搜索
      if (search) {
        query = query.or(`username.ilike.%${search}%,bio.ilike.%${search}%`);
      }

      // 筛选状态
      if (status === 'banned') {
        query = query.eq('is_banned', true);
      } else if (status === 'active') {
        query = query.eq('is_banned', false);
      }

      // 排序和分页
      query = query
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1);

      const { data, error, count } = await query;

      if (error) throw error;

      await logAdminAction(
        supabase,
        user.id,
        'view_user_list',
        'user',
        undefined,
        { page, search, status },
        req
      );

      return successResponse({
        items: data,
        total: count,
        page,
        limit,
        totalPages: Math.ceil((count || 0) / limit),
      });
    }

    // POST: 封禁/解封用户
    if (method === 'POST') {
      requirePermission(user, 'ban_user');

      const body = await req.json();
      const { action, user_id, reason } = body;

      if (!action || !user_id) {
        return errorResponse('Missing required fields: action, user_id');
      }

      if (!['ban', 'unban'].includes(action)) {
        return errorResponse('Invalid action. Must be "ban" or "unban"');
      }

      const updates: Record<string, unknown> = {
        is_banned: action === 'ban',
      };

      if (action === 'ban') {
        updates.banned_at = new Date().toISOString();
        updates.banned_reason = reason || 'No reason provided';
        updates.banned_by = user.id;
      } else {
        updates.banned_at = null;
        updates.banned_reason = null;
        updates.banned_by = null;
      }

      const { data, error } = await supabase
        .from('profiles')
        .update(updates)
        .eq('id', user_id)
        .select()
        .single();

      if (error) throw error;

      await logAdminAction(
        supabase,
        user.id,
        `${action}_user`,
        'user',
        user_id,
        { reason },
        req
      );

      return successResponse({
        message: `User ${action}ned successfully`,
        user: data,
      });
    }

    // DELETE: 删除用户
    if (method === 'DELETE') {
      requirePermission(user, 'delete_user');

      const body = await req.json();
      const { user_id } = body;

      if (!user_id) {
        return errorResponse('Missing required field: user_id');
      }

      // 删除用户（级联删除会自动处理相关数据）
      const { error } = await supabase
        .from('profiles')
        .delete()
        .eq('id', user_id);

      if (error) throw error;

      await logAdminAction(
        supabase,
        user.id,
        'delete_user',
        'user',
        user_id,
        {},
        req
      );

      return successResponse({
        message: 'User deleted successfully',
      });
    }

    return errorResponse('Method not allowed', 405);
  } catch (error) {
    console.error('Error:', error);
    return errorResponse(
      error instanceof Error ? error.message : 'Internal server error',
      error.message?.includes('not an admin') ? 403 : 500
    );
  }
});
