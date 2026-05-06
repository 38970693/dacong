/**
 * 收藏夹 Store - 管理用户收藏的内容（支持 post/review/model）
 */
import { create } from 'zustand';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByc3prZGJkZ2ZmYmRxY2xiZ29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NzUyMDksImV4cCI6MjA5MzI1MTIwOX0.m2eElXYUlB-XHXZ8w988APQs4u1s2rn5VlIOjn2m_t0';
const supabase = createClient(supabaseUrl, supabaseKey);

type TargetType = 'post' | 'review' | 'model';

interface FavoriteItem {
  id: string;
  user_id: string;
  target_type: TargetType;
  target_id: string;
  created_at: string;
}

interface FavoritesState {
  favorites: FavoriteItem[];
  isLoading: boolean;
  error: string | null;
}

interface FavoritesStore extends FavoritesState {
  loadFavorites: (userId: string) => Promise<void>;
  addFavorite: (userId: string, targetType: TargetType, targetId: string) => Promise<boolean>;
  removeFavorite: (userId: string, targetType: TargetType, targetId: string) => Promise<boolean>;
  isFavorited: (targetType: TargetType, targetId: string) => boolean;
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
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      set({ favorites: data || [], isLoading: false });
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Failed to load favorites',
        isLoading: false
      });
    }
  },

  addFavorite: async (userId: string, targetType: TargetType, targetId: string) => {
    if (!userId) return false;
    try {
      const { error } = await supabase
        .from('favorites')
        .insert({ user_id: userId, target_type: targetType, target_id: targetId });

      if (error) {
        console.error('添加收藏失败:', error.message);
        return false;
      }

      set(state => ({
        favorites: [...state.favorites, { id: crypto.randomUUID(), user_id: userId, target_type: targetType, target_id: targetId, created_at: new Date().toISOString() }]
      }));
      return true;
    } catch (err) {
      console.error('添加收藏出错:', err);
      return false;
    }
  },

  removeFavorite: async (userId: string, targetType: TargetType, targetId: string) => {
    if (!userId) return false;
    try {
      const { error } = await supabase
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('target_type', targetType)
        .eq('target_id', targetId);

      if (error) {
        console.error('移除收藏失败:', error.message);
        return false;
      }

      set(state => ({
        favorites: state.favorites.filter(f => !(f.target_type === targetType && f.target_id === targetId))
      }));
      return true;
    } catch (err) {
      console.error('移除收藏出错:', err);
      return false;
    }
  },

  isFavorited: (targetType: TargetType, targetId: string) => {
    return get().favorites.some(f => f.target_type === targetType && f.target_id === targetId);
  },

  clear: () => {
    set({ favorites: [], isLoading: false, error: null });
  }
}));