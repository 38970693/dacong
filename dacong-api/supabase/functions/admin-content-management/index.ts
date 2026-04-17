/**
 * 管理后台 - 内容管理 API
 *
 * 功能：
 * - GET: 获取待审核内容列表（支持分页、筛选、排序）
 * - POST: 审核内容（通过/拒绝）
 * - PUT: 编辑内容
 * - DELETE: 删除内容
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
import { validateBody, validateQuery } from '../_shared/middleware/validation.ts';
import {
  reviewContentSchema,
  editContentSchema,
  deleteContentSchema,
  getContentListSchema,
} from '../_shared/schemas/admin_schemas.ts';
import { sanitizeUserInput } from '../_shared/utils/sanitize.ts';

serve(async (req) => {
  // CORS 处理
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, content-type, x-csrf-token',
      },
    });
  }

  try {
    // CSRF 防护（仅对状态变更操作）
    if (['POST', 'PUT', 'DELETE'].includes(req.method)) {
      const csrfError = await csrfMiddleware(req);
      if (csrfError) return csrfError;
    }

    // 验证管理员身份
    const { user, supabase } = await requireAdmin(req);

    const url = new URL(req.url);
    const method = req.method;

    // GET: 获取内容列表
    if (method === 'GET') {
      requirePermission(user, 'view_content');

      const validation = validateQuery(req, getContentListSchema);
      if (!validation.success) {
        return validation.response;
      }

      const { status, page, limit, search, sort_by, sort_order } = validation.data;
      const offset = (page - 1) * limit;

      let query = supabase
        .from('posts')
        .select('*, profiles(username, avatar_url), topics(name)', { count: 'exact' });

      // 筛选状态
      if (status !== 'all') {
        query = query.eq('moderation_status', status);
      }

      // 搜索
      if (search) {
        const sanitizedSearch = sanitizeUserInput(search);
        query = query.or(`title.ilike.%${sanitizedSearch}%,content.ilike.%${sanitizedSearch}%`);
      }

      // 排序
      query = query.order(sort_by, { ascending: sort_order === 'asc' });

      // 分页
      query = query.range(offset, offset + limit - 1);

      const { data, error, count } = await query;

      if (error) throw error;

      await logAdminAction(
        supabase,
        user.id,
        'view_content_list',
        'content',
        undefined,
        { status, page, search },
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

    // POST: 审核内容
    if (method === 'POST') {
      requirePermission(user, 'moderate_content');

      const validation = await validateBody(req, reviewContentSchema);
      if (!validation.success) {
        return validation.response;
      }

      const { action, content_ids, reason } = validation.data;
      const newStatus = action === 'approve' ? 'passed' : 'flagged';

      // 批量更新状态
      const { data, error } = await supabase
        .from('posts')
        .update({ moderation_status: newStatus })
        .in('id', content_ids)
        .select();

      if (error) throw error;

      // 记录日志
      await logAdminAction(
        supabase,
        user.id,
        `${action}_content`,
        'content',
        content_ids.join(','),
        { reason, count: content_ids.length },
        req
      );

      return successResponse({
        message: `Successfully ${action}ed ${content_ids.length} items`,
        updated: data,
      });
    }

    // PUT: 编辑内容
    if (method === 'PUT') {
      requirePermission(user, 'edit_content');

      const validation = await validateBody(req, editContentSchema);
      if (!validation.success) {
        return validation.response;
      }

      const { content_id, title, content, topic_id } = validation.data;

      const updates: Record<string, unknown> = {};
      if (title !== undefined) updates.title = sanitizeUserInput(title);
      if (content !== undefined) updates.content = sanitizeUserInput(content);
      if (topic_id !== undefined) updates.topic_id = topic_id;

      const { data, error } = await supabase
        .from('posts')
        .update(updates)
        .eq('id', content_id)
        .select()
        .single();

      if (error) throw error;

      await logAdminAction(
        supabase,
        user.id,
        'edit_content',
        'content',
        content_id,
        { updates },
        req
      );

      return successResponse({
        message: 'Content updated successfully',
        content: data,
      });
    }

    // DELETE: 删除内容
    if (method === 'DELETE') {
      requirePermission(user, 'delete_content');

      const validation = await validateBody(req, deleteContentSchema);
      if (!validation.success) {
        return validation.response;
      }

      const { content_ids } = validation.data;

      const { error } = await supabase
        .from('posts')
        .delete()
        .in('id', content_ids);

      if (error) throw error;

      await logAdminAction(
        supabase,
        user.id,
        'delete_content',
        'content',
        content_ids.join(','),
        { count: content_ids.length },
        req
      );

      return successResponse({
        message: `Successfully deleted ${content_ids.length} items`,
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
