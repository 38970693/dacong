/**
 * 通知服务 - 处理用户通知的创建和管理
 */
import { createClient, SupabaseClient } from '@supabase/supabase-js';

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

export type NotificationType = 'reply' | 'mention' | 'like';

export interface Notification {
  id: string;
  user_id: string;
  type: NotificationType;
  title: string;
  content: string;
  related_id: string | null;
  related_type: string | null;
  is_read: boolean;
  created_at: string;
}

export interface CreateReplyNotificationParams {
  /** 被回复的评论的作者 ID */
  parentCommentAuthorId: string;
  /** 回复者的 ID */
  replyAuthorId: string;
  /** 回复内容 */
  replyContent: string;
  /** 回复的评论 ID */
  replyId: string;
  /** 目标类型: post, review */
  targetType: 'post' | 'review';
  /** 目标 ID */
  targetId: string;
  /** 回复者用户名（可选，用于通知内容） */
  replyAuthorName?: string;
}

/**
 * 获取用户信息
 */
async function getUserInfo(userId: string): Promise<{ username?: string } | null> {
  const client = getSupabaseClient();
  if (!client) return null;

  try {
    const { data, error } = await client
      .from('profiles')
      .select('username')
      .eq('id', userId)
      .single();

    if (error || !data) return null;
    return { username: data.username };
  } catch {
    return null;
  }
}

/**
 * 创建回复通知
 * 当用户回复某条评论时，通知原评论作者
 */
export async function createReplyNotification(
  params: CreateReplyNotificationParams
): Promise<Notification | null> {
  const client = getSupabaseClient();
  if (!client) {
    console.error('通知服务: Supabase 客户端未初始化');
    return null;
  }

  const {
    parentCommentAuthorId,
    replyAuthorId,
    replyContent,
    replyId,
    targetType,
    targetId,
    replyAuthorName,
  } = params;

  // 不给自己发通知
  if (parentCommentAuthorId === replyAuthorId) {
    return null;
  }

  // 获取回复者用户名（如果未提供）
  let authorName = replyAuthorName;
  if (!authorName) {
    const userInfo = await getUserInfo(replyAuthorId);
    authorName = userInfo?.username || '某用户';
  }

  // 截取回复内容预览（最多 50 字符）
  const contentPreview = replyContent.length > 50
    ? replyContent.substring(0, 50) + '...'
    : replyContent;

  const notification = {
    user_id: parentCommentAuthorId,
    type: 'reply' as NotificationType,
    title: `${authorName} 回复了你的评论`,
    content: contentPreview,
    related_id: replyId,
    related_type: 'comment',
    is_read: false,
  };

  try {
    const { data, error } = await client
      .from('notifications')
      .insert([notification])
      .select()
      .single();

    if (error) {
      console.error('创建回复通知失败:', error.message);
      return null;
    }

    return {
      id: data.id,
      user_id: data.user_id,
      type: data.type,
      title: data.title,
      content: data.content,
      related_id: data.related_id,
      related_type: data.related_type,
      is_read: data.is_read,
      created_at: data.created_at,
    };
  } catch (error) {
    console.error('创建回复通知异常:', error);
    return null;
  }
}

/**
 * 创建 @提及 通知
 */
export async function createMentionNotification(params: {
  mentionedUserId: string;
  mentionerUserId: string;
  content: string;
  relatedId: string;
  relatedType: 'comment' | 'post' | 'review';
}): Promise<Notification | null> {
  const client = getSupabaseClient();
  if (!client) return null;

  const { mentionedUserId, mentionerUserId, content, relatedId, relatedType } = params;

  if (mentionedUserId === mentionerUserId) return null;

  const authorName = (await getUserInfo(mentionerUserId))?.username || '某用户';
  const contentPreview = content.length > 50 ? content.substring(0, 50) + '...' : content;

  try {
    const { data, error } = await client
      .from('notifications')
      .insert([{
        user_id: mentionedUserId,
        type: 'mention',
        title: `${authorName} 在评论中提到了你`,
        content: contentPreview,
        related_id: relatedId,
        related_type: relatedType,
        is_read: false,
      }])
      .select()
      .single();

    if (error) return null;

    return data;
  } catch {
    return null;
  }
}

/**
 * 创建点赞通知
 */
export async function createLikeNotification(params: {
  ownerUserId: string;
  likerUserId: string;
  contentType: 'comment' | 'post' | 'review';
  relatedId: string;
}): Promise<Notification | null> {
  const client = getSupabaseClient();
  if (!client) return null;

  const { ownerUserId, likerUserId, contentType, relatedId } = params;

  if (ownerUserId === likerUserId) return null;

  const likerName = (await getUserInfo(likerUserId))?.username || '某用户';

  try {
    const { data, error } = await client
      .from('notifications')
      .insert([{
        user_id: ownerUserId,
        type: 'like',
        title: `${likerName} 赞了你的${contentType === 'comment' ? '评论' : '内容'}`,
        content: '',
        related_id: relatedId,
        related_type: contentType,
        is_read: false,
      }])
      .select()
      .single();

    if (error) return null;

    return data;
  } catch {
    return null;
  }
}