/**
 * 管理后台 - 评论审核 API
 *
 * 功能：
 * - GET: 获取待审核评论列表
 * - POST: 审核评论（通过/删除/封禁用户）
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

// 敏感词列表（简化版，实际应该从配置或数据库读取）
const SENSITIVE_WORDS = [
  '垃圾', '骗子', '傻逼', '操你', '妈的', '草泥马',
  'fuck', 'shit', 'damn', 'bitch',
];

/**
 * 高亮敏感词
 */
function highlightSensitiveWords(text: string): { text: string; hasSensitive: boolean } {
  let highlighted = text;
  let hasSensitive = false;

  for (const word of SENSITIVE_WORDS) {
    const regex = new RegExp(word, 'gi');
    if (regex.test(text)) {
      hasSensitive = true;
      highlighted = highlighted.replace(regex, `**${word}**`);
    }
  }

  return { text: highlighted, hasSensitive };
}

serve(async (req) => {
  // CORS 处理
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, content-type, x-csrf-token',
      },
    });
  }

  try {
    // CSRF 防护（仅对状态变更操作）
    if (req.method === 'POST') {
      const csrfError = await csrfMiddleware(req);
      if (csrfError) return csrfError;
    }

    const { user, supabase } = await requireAdmin(req);
    const url = new URL(req.url);
    const method = req.method;

    // GET: 获取待审核评论列表
    if (method === 'GET') {
      requirePermission(user, 'view_comments');

      const page = parseInt(url.searchParams.get('page') || '1');
      const limit = parseInt(url.searchParams.get('limit') || '20');
      const status = url.searchParams.get('status') || 'pending';
      const reportedOnly = url.searchParams.get('reported_only') === 'true';

      const offset = (page - 1) * limit;

      let query = supabase
        .from('comments')
        .select(`
          *,
          profiles!comments_user_id_fkey(username, avatar_url),
          posts!comments_post_id_fkey(title)
        `, { count: 'exact' });

      // 筛选状态
      if (status !== 'all') {
        if (status === 'flagged') {
          query = query.eq('is_flagged', true);
        } else if (status === 'pending') {
          query = query.eq('moderation_status', 'pending');
        }
      }

      // 只显示被举报的
      if (reportedOnly) {
        const { data: reportedCommentIds } = await supabase
          .from('comment_reports')
          .select('comment_id')
          .eq('status', 'pending');

        if (reportedCommentIds && reportedCommentIds.length > 0) {
          const ids = reportedCommentIds.map((r) => r.comment_id);
          query = query.in('id', ids);
        } else {
          // 没有被举报的评论
          return successResponse({
            items: [],
            total: 0,
            page,
            limit,
            totalPages: 0,
          });
        }
      }

      // 排序和分页
      query = query
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1);

      const { data, error, count } = await query;

      if (error) throw error;

      // 为每条评论添加举报信息和敏感词高亮
      const enrichedData = await Promise.all(
        (data || []).map(async (comment) => {
          // 获取举报信息
          const { data: reports } = await supabase
            .from('comment_reports')
            .select('*')
            .eq('comment_id', comment.id)
            .eq('status', 'pending');

          // 高亮敏感词
          const { text: highlightedContent, hasSensitive } = highlightSensitiveWords(
            comment.content
          );

          return {
            ...comment,
            highlighted_content: highlightedContent,
            has_sensitive_words: hasSensitive,
            reports: reports || [],
            report_count: reports?.length || 0,
          };
        })
      );

      await logAdminAction(
        supabase,
        user.id,
        'view_comment_list',
        'comment',
        undefined,
        { page, status, reportedOnly },
        req
      );

      return successResponse({
        items: enrichedData,
        total: count,
        page,
        limit,
        totalPages: Math.ceil((count || 0) / limit),
      });
    }

    // POST: 审核评论
    if (method === 'POST') {
      requirePermission(user, 'moderate_comments');

      const body = await req.json();
      const { action, comment_ids, reason, ban_user } = body;

      if (!action || !comment_ids || !Array.isArray(comment_ids)) {
        return errorResponse('Missing required fields: action, comment_ids');
      }

      if (!['approve', 'reject', 'delete'].includes(action)) {
        return errorResponse('Invalid action. Must be "approve", "reject", or "delete"');
      }

      let result;

      if (action === 'delete') {
        // 删除评论
        const { error } = await supabase
          .from('comments')
          .delete()
          .in('id', comment_ids);

        if (error) throw error;

        result = { deleted: comment_ids.length };
      } else {
        // 更新审核状态
        const newStatus = action === 'approve' ? 'approved' : 'rejected';
        const { data, error } = await supabase
          .from('comments')
          .update({
            moderation_status: newStatus,
            is_flagged: action === 'reject',
          })
          .in('id', comment_ids)
          .select();

        if (error) throw error;

        result = { updated: data };
      }

      // 更新举报状态
      await supabase
        .from('comment_reports')
        .update({
          status: 'reviewed',
          reviewed_by: user.id,
          reviewed_at: new Date().toISOString(),
        })
        .in('comment_id', comment_ids);

      // 如果需要封禁用户
      if (ban_user && comment_ids.length > 0) {
        // 获取评论的作者
        const { data: comments } = await supabase
          .from('comments')
          .select('user_id')
          .in('id', comment_ids);

        if (comments && comments.length > 0) {
          const userIds = [...new Set(comments.map((c) => c.user_id))];

          await supabase
            .from('profiles')
            .update({
              is_banned: true,
              banned_at: new Date().toISOString(),
              banned_reason: reason || 'Inappropriate comments',
              banned_by: user.id,
            })
            .in('id', userIds);

          await logAdminAction(
            supabase,
            user.id,
            'ban_user_from_comment',
            'user',
            userIds.join(','),
            { reason, comment_ids },
            req
          );
        }
      }

      await logAdminAction(
        supabase,
        user.id,
        `${action}_comment`,
        'comment',
        comment_ids.join(','),
        { reason, ban_user, count: comment_ids.length },
        req
      );

      return successResponse({
        message: `Successfully ${action}ed ${comment_ids.length} comments`,
        ...result,
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
