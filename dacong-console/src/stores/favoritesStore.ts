/**
 * 收藏夹 Store - 管理用户收藏的帖子
 */
import { create } from 'zustand';
import { createClient } from '@supabase/supabase-js';
import type { Post } from '@/types/database';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByc3prZGJkZ2ZmYmRxY2xiZ29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NzUyMDksImV4cCI6MjA5MzI1MTIwOX0.m2eElXYUlB-XHXZ8w988APQs4u1s2rn5VlIOjn2m_t0';
const supabase = createClient(supabaseUrl, supabaseKey);

interface FavoritesState {
  favorites: string[]; // 收藏的帖子 ID 列表
  isLoading: boolean;
  error: string | null;
}

interface FavoritesStore extends FavoritesState {
  // 加载用户的收藏列表
  loadFavorites: (userId: string) => Promise<void>;
  // 添加收藏
  addFavorite: (userId: string, postId: string) => Promise<boolean>;
  // 移除收藏
  removeFavorite: (userId: string, postId: string) => Promise<boolean>;
  // 检查是否已收藏
  isFavorited: (postId: string) => boolean;
  // 清空收藏列表
  clear: () => void;
}

export const useFavoritesStore = create<FavoritesStore>((set, get) => ({
  favorites: [],
  isLoading: false,
  error: null,

  loadFavorites: async (userId: string) => {
    if (!userId) return;
    set({ isLoading: true, error: null });
    try {
      const { data, error } = await supabase
        .from('favorites')
        .select('post_id')
        .eq('user_id', userId);

      if (error) throw error;
      set({
        favorites: data?.map(f => f.post_id) || [],
        isLoading: false
      });
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Failed to load favorites',
        isLoading: false
      });
    }
  },

  addFavorite: async (userId: string, postId: string) => {
    if (!userId) return false;
    try {
      const { error } = await supabase
        .from('favorites')
        .insert({ user_id: userId, post_id: postId });

      if (error) {
        console.error('添加收藏失败:', error.message);
        return false;
      }

      // 乐观更新
      set(state => ({
        favorites: [...state.favorites, postId]
      }));
      return true;
    } catch (err) {
      console.error('添加收藏出错:', err);
      return false;
    }
  },

  removeFavorite: async (userId: string, postId: string) => {
    if (!userId) return false;
    try {
      const { error } = await supabase
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('post_id', postId);

      if (error) {
        console.error('移除收藏失败:', error.message);
        return false;
      }

      // 乐观更新
      set(state => ({
        favorites: state.favorites.filter(id => id !== postId)
      }));
      return true;
    } catch (err) {
      console.error('移除收藏出错:', err);
      return false;
    }
  },

  isFavorited: (postId: string) => {
    return get().favorites.includes(postId);
  },

  clear: () => {
    set({ favorites: [], isLoading: false, error: null });
  }
}));