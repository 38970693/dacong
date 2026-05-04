/**
 * 点赞 Store - 管理用户点赞的帖子
 */
import { create } from 'zustand';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByc3prZGJkZ2ZmYmRxY2xiZ29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NzUyMDksImV4cCI6MjA5MzI1MTIwOX0.m2eElXYUlB-XHXZ8w988APQs4u1s2rn5VlIOjn2m_t0';
const supabase = createClient(supabaseUrl, supabaseKey);

interface LikesState {
  likes: string[]; // 点赞的帖子 ID 列表
  isLoading: boolean;
  error: string | null;
}

interface LikesStore extends LikesState {
  // 加载用户的点赞列表
  loadLikes: (userId: string) => Promise<void>;
  // 点赞帖子
  likePost: (userId: string, postId: string) => Promise<boolean>;
  // 取消点赞
  unlikePost: (userId: string, postId: string) => Promise<boolean>;
  // 检查是否已点赞
  isLiked: (postId: string) => boolean;
  // 清空点赞列表
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
        .select('post_id')
        .eq('user_id', userId);

      if (error) throw error;
      set({
        likes: data?.map(l => l.post_id) || [],
        isLoading: false
      });
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Failed to load likes',
        isLoading: false
      });
    }
  },

  likePost: async (userId: string, postId: string) => {
    if (!userId) return false;
    try {
      const { error } = await supabase
        .from('likes')
        .insert({ user_id: userId, post_id: postId });

      if (error) {
        console.error('点赞失败:', error.message);
        return false;
      }

      // 乐观更新
      set(state => ({
        likes: [...state.likes, postId]
      }));
      return true;
    } catch (err) {
      console.error('点赞出错:', err);
      return false;
    }
  },

  unlikePost: async (userId: string, postId: string) => {
    if (!userId) return false;
    try {
      const { error } = await supabase
        .from('likes')
        .delete()
        .eq('user_id', userId)
        .eq('post_id', postId);

      if (error) {
        console.error('取消点赞失败:', error.message);
        return false;
      }

      // 乐观更新
      set(state => ({
        likes: state.likes.filter(id => id !== postId)
      }));
      return true;
    } catch (err) {
      console.error('取消点赞出错:', err);
      return false;
    }
  },

  isLiked: (postId: string) => {
    return get().likes.includes(postId);
  },

  clear: () => {
    set({ likes: [], isLoading: false, error: null });
  }
}));