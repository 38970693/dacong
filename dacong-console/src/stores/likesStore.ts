/**
 * 点赞 Store - 管理用户点赞的内容（支持 post/review/model）
 */
import { create } from 'zustand';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByc3prZGJkZ2ZmYmRxY2xiZ29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NzUyMDksImV4cCI6MjA5MzI1MTIwOX0.m2eElXYUlB-XHXZ8w988APQs4u1s2rn5VlIOjn2m_t0';
const supabase = createClient(supabaseUrl, supabaseKey);

type TargetType = 'post' | 'review' | 'model';

interface LikeItem {
  id: string;
  user_id: string;
  target_type: TargetType;
  target_id: string;
  created_at: string;
}

interface LikesState {
  likes: LikeItem[];
  isLoading: boolean;
  error: string | null;
}

interface LikesStore extends LikesState {
  loadLikes: (userId: string) => Promise<void>;
  like: (userId: string, targetType: TargetType, targetId: string) => Promise<boolean>;
  unlike: (userId: string, targetType: TargetType, targetId: string) => Promise<boolean>;
  isLiked: (targetType: TargetType, targetId: string) => boolean;
  clear: () => void;
}

export const useLikesStore = create<LikesStore>((set, get) => ({
  likes: [],
  isLoading: false,
  error: null,

  loadLikes: async (userId: string) => {
    if (!userId) return;
    set({ isLoading: true, error: null });
    try {
      const { data, error } = await supabase
        .from('likes')
        .select('*')
        .eq('user_id', userId);

      if (error) throw error;
      set({ likes: data || [], isLoading: false });
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Failed to load likes',
        isLoading: false
      });
    }
  },

  like: async (userId: string, targetType: TargetType, targetId: string) => {
    if (!userId) return false;
    try {
      const { error } = await supabase
        .from('likes')
        .insert({ user_id: userId, target_type: targetType, target_id: targetId });

      if (error) {
        console.error('点赞失败:', error.message);
        return false;
      }

      set(state => ({
        likes: [...state.likes, { id: crypto.randomUUID(), user_id: userId, target_type: targetType, target_id: targetId, created_at: new Date().toISOString() }]
      }));
      return true;
    } catch (err) {
      console.error('点赞出错:', err);
      return false;
    }
  },

  unlike: async (userId: string, targetType: TargetType, targetId: string) => {
    if (!userId) return false;
    try {
      const { error } = await supabase
        .from('likes')
        .delete()
        .eq('user_id', userId)
        .eq('target_type', targetType)
        .eq('target_id', targetId);

      if (error) {
        console.error('取消点赞失败:', error.message);
        return false;
      }

      set(state => ({
        likes: state.likes.filter(l => !(l.target_type === targetType && l.target_id === targetId))
      }));
      return true;
    } catch (err) {
      console.error('取消点赞出错:', err);
      return false;
    }
  },

  isLiked: (targetType: TargetType, targetId: string) => {
    return get().likes.some(l => l.target_type === targetType && l.target_id === targetId);
  },

  clear: () => {
    set({ likes: [], isLoading: false, error: null });
  }
}));