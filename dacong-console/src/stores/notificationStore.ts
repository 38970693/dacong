/**
 * 通知 Store - 管理用户站内通知
 */
import { create } from 'zustand';

export type NotificationType =
  | 'system.announcement' | 'system.update' | 'system.maintenance'
  | 'content.reply' | 'content.mention' | 'content.like' | 'content.favorite'
  | 'review.published' | 'review.commented' | 'review.liked'
  | 'follow.new_follower';

export type NotificationPriority = 'low' | 'normal' | 'high' | 'urgent';

export interface Notification {
  id: string;
  user_id: string;
  type: NotificationType;
  title: string;
  content: string;
  action_url: string | null;
  target_type: string | null;
  target_id: string | null;
  source_user_id: string | null;
  source_user_name: string | null;
  source_user_avatar: string | null;
  is_read: boolean;
  read_at: string | null;
  priority: NotificationPriority;
  expires_at: string | null;
  metadata: Record<string, unknown> | null;
  created_at: string;
  updated_at: string;
}

interface NotificationState {
  notifications: Notification[];
  unreadCount: number;
  isLoading: boolean;
  error: string | null;
}

interface NotificationStore extends NotificationState {
  fetchNotifications: (userId: string) => Promise<void>;
  fetchUnreadCount: (userId: string) => Promise<void>;
  markAsRead: (notificationId: string) => Promise<boolean>;
  markAllAsRead: (userId: string) => Promise<boolean>;
  deleteNotification: (notificationId: string) => Promise<boolean>;
  clear: () => void;
}

// Supabase 客户端
import { createClient } from '@supabase/supabase-js';
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error('NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY must be configured');
}

const supabase = createClient(supabaseUrl, supabaseKey);

export const useNotificationStore = create<NotificationStore>((set, get) => ({
  notifications: [],
  unreadCount: 0,
  isLoading: false,
  error: null,

  fetchNotifications: async (userId: string) => {
    if (!userId) return;
    set({ isLoading: true, error: null });

    try {
      const { data, error } = await supabase
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .limit(50);

      if (error) throw error;

      const unreadCount = (data || []).filter(n => !n.is_read).length;

      set({
        notifications: data as Notification[],
        unreadCount,
        isLoading: false
      });
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Failed to fetch notifications',
        isLoading: false
      });
    }
  },

  fetchUnreadCount: async (userId: string) => {
    if (!userId) return;

    try {
      const { count, error } = await supabase
        .from('notifications')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('is_read', false);

      if (error) throw error;

      set({ unreadCount: count || 0 });
    } catch (error) {
      console.error('获取未读数失败:', error);
    }
  },

  markAsRead: async (notificationId: string) => {
    try {
      const { error } = await supabase
        .from('notifications')
        .update({ is_read: true, read_at: new Date().toISOString() })
        .eq('id', notificationId);

      if (error) {
        console.error('标记已读失败:', error.message);
        return false;
      }

      set(state => ({
        notifications: state.notifications.map(n =>
          n.id === notificationId ? { ...n, is_read: true, read_at: new Date().toISOString() } : n
        ),
        unreadCount: Math.max(0, state.unreadCount - 1)
      }));

      return true;
    } catch (err) {
      console.error('标记已读出错:', err);
      return false;
    }
  },

  markAllAsRead: async (userId: string) => {
    try {
      const { error } = await supabase
        .from('notifications')
        .update({ is_read: true, read_at: new Date().toISOString() })
        .eq('user_id', userId)
        .eq('is_read', false);

      if (error) {
        console.error('批量标记已读失败:', error.message);
        return false;
      }

      set(state => ({
        notifications: state.notifications.map(n => ({ ...n, is_read: true, read_at: n.read_at || new Date().toISOString() })),
        unreadCount: 0
      }));

      return true;
    } catch (err) {
      console.error('批量标记已读出错:', err);
      return false;
    }
  },

  deleteNotification: async (notificationId: string) => {
    try {
      const { error } = await supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId);

      if (error) {
        console.error('删除通知失败:', error.message);
        return false;
      }

      const notification = get().notifications.find(n => n.id === notificationId);
      set(state => ({
        notifications: state.notifications.filter(n => n.id !== notificationId),
        unreadCount: notification && !notification.is_read
          ? Math.max(0, state.unreadCount - 1)
          : state.unreadCount
      }));

      return true;
    } catch (err) {
      console.error('删除通知出错:', err);
      return false;
    }
  },

  clear: () => {
    set({ notifications: [], unreadCount: 0, isLoading: false, error: null });
  }
}));

// 便捷函数：创建通知
export async function createNotification(data: {
  userId: string;
  type: NotificationType;
  title: string;
  content: string;
  actionUrl?: string;
  targetType?: string;
  targetId?: string;
  sourceUserId?: string;
  sourceUserName?: string;
  sourceUserAvatar?: string;
  priority?: NotificationPriority;
  expiresAt?: string;
  metadata?: Record<string, unknown>;
}): Promise<boolean> {
  try {
    const { error } = await supabase
      .from('notifications')
      .insert([{
        user_id: data.userId,
        type: data.type,
        title: data.title,
        content: data.content,
        action_url: data.actionUrl || null,
        target_type: data.targetType || null,
        target_id: data.targetId || null,
        source_user_id: data.sourceUserId || null,
        source_user_name: data.sourceUserName || null,
        source_user_avatar: data.sourceUserAvatar || null,
        priority: data.priority || 'normal',
        expires_at: data.expiresAt || null,
        metadata: data.metadata || null
      }]);

    if (error) {
      console.error('创建通知失败:', error.message);
      return false;
    }

    return true;
  } catch (err) {
    console.error('创建通知出错:', err);
    return false;
  }
}