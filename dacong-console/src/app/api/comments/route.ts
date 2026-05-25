// Static export mode: exclude from static generation
export const dynamic = 'force-static';

import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';
import type { Comment } from '@/types/database';
import { getCurrentUser, getUserProfile } from '@/lib/auth-utils';
import { createReplyNotification } from '@/lib/notification-service';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

// 创建单例 supabase 客户端
let supabase: ReturnType<typeof createClient> | null = null;

function getSupabaseClient() {
  if (!supabase && supabaseKey) {
    supabase = createClient(supabaseUrl, supabaseKey);
  }
  return supabase;
}

// 类型定义（使用数据库的 snake_case）
interface CommentWithUser {
  id: string;
  target_type: 'post' | 'review';
  target_id: string;
  user_id: string;
  content: string;
  parent_id: string | null;
  likes: number;
  created_at: string;
  updated_at: string;
  user?: {
    id: string;
    username: string;
    avatar: string | null;
  };
  replies?: CommentWithUser[];
}

interface CommentRow {
  id: string;
  target_type: 'post' | 'review';
  target_id: string;
  user_id: string;
  content: string;
  parent_id: string | null;
  likes: number;
  created_at: string;
  updated_at: string;
  user_email?: string;
}

// GET /api/comments - 获取评论列表
export async function GET(request: NextRequest) {
  try {
    const client = getSupabaseClient();
    if (!client) {
      return NextResponse.json(
        { success: false, error: 'Database not configured' },
        { status: 500 }
      );
    }

    const searchParams = request.nextUrl.searchParams;
    const targetType = searchParams.get('target_type');
    const targetId = searchParams.get('target_id');
    const page = parseInt(searchParams.get('page') || '1', 10);
    const limit = Math.min(parseInt(searchParams.get('limit') || '20', 10), 100);
    const sort = searchParams.get('sort') || 'latest';

    // 验证必填参数
    if (!targetType || !['post', 'review'].includes(targetType)) {
      return NextResponse.json(
        { success: false, error: 'target_type must be "post" or "review"' },
        { status: 400 }
      );
    }

    if (!targetId) {
      return NextResponse.json(
        { success: false, error: 'target_id is required' },
        { status: 400 }
      );
    }

    const offset = (page - 1) * limit;

    // 构建排序
    const orderColumn = sort === 'popular' ? 'likes' : 'created_at';
    const orderAscending = sort !== 'popular';

    // 查询顶级评论（parent_id 为 null）
    const { data: topLevelComments, error: topError, count } = await client
      .from('comments')
      .select(`
        id,
        target_type,
        target_id,
        user_id,
        content,
        parent_id,
        likes,
        created_at,
        updated_at
      `, { count: 'exact' })
      .eq('target_type', targetType)
      .eq('target_id', targetId)
      .is('parent_id', null)
      .order(orderColumn, { ascending: orderAscending })
      .range(offset, offset + limit - 1) as { data: CommentRow[] | null; error: null; count: number | null };

    if (topError) throw topError;

    // 查询所有顶级评论的回复
    const topLevelIds = (topLevelComments as CommentRow[] | null || []).map(c => c.id);
    let repliesMap: Record<string, CommentRow[]> = {};

    if (topLevelIds.length > 0) {
      const { data: allReplies } = await client
        .from('comments')
        .select(`
          id,
          target_type,
          target_id,
          user_id,
          content,
          parent_id,
          likes,
          created_at,
          updated_at
        `)
        .in('parent_id', topLevelIds)
        .order('created_at', { ascending: true }) as { data: CommentRow[] | null };

      // 按 parent_id 分组
      if (allReplies) {
        for (const reply of allReplies) {
          if (reply.parent_id) {
            if (!repliesMap[reply.parent_id]) {
              repliesMap[reply.parent_id] = [];
            }
            repliesMap[reply.parent_id].push(reply as CommentRow);
          }
        }
      }
    }

    // 构建响应数据
    const comments: CommentWithUser[] = (topLevelComments || []).map(comment => ({
      id: comment.id,
      target_type: comment.target_type,
      target_id: comment.target_id,
      user_id: comment.user_id,
      content: comment.content,
      parent_id: comment.parent_id,
      likes: comment.likes,
      created_at: comment.created_at,
      updated_at: comment.updated_at,
      replies: (repliesMap[comment.id] || []).map(reply => ({
        id: reply.id,
        target_type: reply.target_type,
        target_id: reply.target_id,
        user_id: reply.user_id,
        content: reply.content,
        parent_id: reply.parent_id,
        likes: reply.likes,
        created_at: reply.created_at,
        updated_at: reply.updated_at,
      })),
    }));

    const total = count || 0;
    const hasMore = offset + (topLevelComments?.length || 0) < total;

    return NextResponse.json({
      success: true,
      data: {
        comments,
        total,
        page,
        limit,
        hasMore,
      },
    });
  } catch (error) {
    console.error('Comments API GET error:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to fetch comments' },
      { status: 500 }
    );
  }
}

// POST /api/comments - 创建评论
export async function POST(request: NextRequest) {
  try {
    const client = getSupabaseClient();
    if (!client) {
      return NextResponse.json(
        { success: false, error: 'Database not configured' },
        { status: 500 }
      );
    }

    // 获取当前用户
    const user = await getCurrentUser(request);

    const body = await request.json();
    const { target_type, target_id, content, parent_id } = body;

    // 验证必填字段
    if (!target_type || !['post', 'review'].includes(target_type)) {
      return NextResponse.json(
        { success: false, error: 'target_type must be "post" or "review"' },
        { status: 400 }
      );
    }

    if (!target_id || typeof target_id !== 'string') {
      return NextResponse.json(
        { success: false, error: 'target_id is required' },
        { status: 400 }
      );
    }

    if (!content || typeof content !== 'string' || content.trim().length === 0) {
      return NextResponse.json(
        { success: false, error: 'content is required and cannot be empty' },
        { status: 400 }
      );
    }

    if (content.length > 2000) {
      return NextResponse.json(
        { success: false, error: 'content exceeds maximum length of 2000 characters' },
        { status: 400 }
      );
    }

    // 验证 parent_id 如果提供，并获取被回复评论的作者信息
    let parentCommentAuthorId: string | null = null;
    if (parent_id) {
      const { data: parentComment } = await client
        .from('comments')
        .select('id, user_id')
        .eq('id', parent_id)
        .single() as { data: { id: string; user_id: string } | null };

      if (!parentComment) {
        return NextResponse.json(
          { success: false, error: 'parent comment not found' },
          { status: 404 }
        );
      }
      parentCommentAuthorId = parentComment.user_id;
    }

    // 使用已认证用户的 ID，或在开发模式下允许匿名
    const commentUserId = user?.id || (process.env.NODE_ENV === 'development' ? 'anonymous' : null);

    if (!commentUserId) {
      return NextResponse.json(
        { success: false, error: 'Authentication required' },
        { status: 401 }
      );
    }

    const now = new Date().toISOString();
    const newComment = {
      target_type,
      target_id,
      user_id: commentUserId,
      content: content.trim(),
      parent_id: parent_id || null,
      likes: 0,
      created_at: now,
      updated_at: now,
    };

    const { data, error } = await client
      .from('comments')
      .insert([newComment] as never)
      .select(`
        id,
        target_type,
        target_id,
        user_id,
        content,
        parent_id,
        likes,
        created_at,
        updated_at
      `)
      .single() as { data: CommentRow | null; error: null };

    if (error) throw error;
    if (!data) {
      return NextResponse.json(
        { success: false, error: 'Failed to create comment' },
        { status: 500 }
      );
    }

    const comment: CommentWithUser = {
      id: data.id,
      target_type: data.target_type,
      target_id: data.target_id,
      user_id: data.user_id,
      content: data.content,
      parent_id: data.parent_id,
      likes: data.likes,
      created_at: data.created_at,
      updated_at: data.updated_at,
    };

    // 如果是回复评论，发送通知给原评论作者
    if (parent_id && parentCommentAuthorId && commentUserId !== parentCommentAuthorId) {
      const replyAuthorProfile = await getUserProfile(commentUserId);
      createReplyNotification({
        parentCommentAuthorId,
        replyAuthorId: commentUserId,
        replyContent: content,
        replyId: data.id,
        targetType: target_type,
        targetId: target_id,
        replyAuthorName: replyAuthorProfile?.username,
      }).catch(err => console.error('发送回复通知失败:', err));
    }

    return NextResponse.json({ success: true, data: comment });
  } catch (error) {
    console.error('Comments API POST error:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to create comment' },
      { status: 500 }
    );
  }
}