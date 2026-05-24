/**
 * 收藏夹 Store - 管理用户收藏的内容（支持 post/review/model）
 */
import { create } from 'zustand';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error('NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY must be configured');
}

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

    // 乐观更新本地状态
    const newFavorite = { id: crypto.randomUUID(), user_id: userId, target_type: targetType, target_id: targetId, created_at: new Date().toISOString() };
    set(state => ({
      favorites: [...state.favorites, newFavorite]
    }));

    try {
      const { error } = await supabase
        .from('favorites')
        .insert({ user_id: userId, target_type: targetType, target_id: targetId });

      if (error) {
        console.error('添加收藏失败:', error.message);
        // 数据库插入失败，回滚本地状态
        set(state => ({
          favorites: state.favorites.filter(f => !(f.target_type === targetType && f.target_id === targetId))
        }));
        return false;
      }
      return true;
    } catch (err) {
      console.error('添加收藏出错:', err);
      // 异常时回滚
      set(state => ({
        favorites: state.favorites.filter(f => !(f.target_type === targetType && f.target_id === targetId))
      }));
      return false;
    }
  },

  removeFavorite: async (userId: string, targetType: TargetType, targetId: string) => {
    if (!userId) return false;

    // 保存当前状态用于回滚
    const previousFavorites = get().favorites;
    const targetFavorite = previousFavorites.find(f => f.target_type === targetType && f.target_id === targetId);

    // 乐观更新本地状态
    set(state => ({
      favorites: state.favorites.filter(f => !(f.target_type === targetType && f.target_id === targetId))
    }));

    try {
      const { error } = await supabase
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('target_type', targetType)
        .eq('target_id', targetId);

      if (error) {
        console.error('移除收藏失败:', error.message);
        // 回滚本地状态
        if (targetFavorite) {
          set({ favorites: [...previousFavorites] });
        }
        return false;
      }
      return true;
    } catch (err) {
      console.error('移除收藏出错:', err);
      // 回滚本地状态
      if (targetFavorite) {
        set({ favorites: [...previousFavorites] });
      }
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