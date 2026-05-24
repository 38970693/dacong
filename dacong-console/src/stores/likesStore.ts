/**
 * 点赞 Store - 管理用户点赞的内容（支持 post/review/model）
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

    // 乐观更新本地状态
    const newLike = { id: crypto.randomUUID(), user_id: userId, target_type: targetType, target_id: targetId, created_at: new Date().toISOString() };
    set(state => ({
      likes: [...state.likes, newLike]
    }));

    try {
      const { error } = await supabase
        .from('likes')
        .insert({ user_id: userId, target_type: targetType, target_id: targetId });

      if (error) {
        // 数据库插入失败，回滚本地状态
        console.error('点赞失败:', error.message);
        set(state => ({
          likes: state.likes.filter(l => !(l.target_type === targetType && l.target_id === targetId))
        }));
        return false;
      }
      return true;
    } catch (err) {
      // 异常时回滚
      console.error('点赞出错:', err);
      set(state => ({
        likes: state.likes.filter(l => !(l.target_type === targetType && l.target_id === targetId))
      }));
      return false;
    }
  },

  unlike: async (userId: string, targetType: TargetType, targetId: string) => {
    if (!userId) return false;

    // 保存当前状态用于回滚
    const previousLikes = get().likes;
    const targetLike = previousLikes.find(l => l.target_type === targetType && l.target_id === targetId);

    // 乐观更新本地状态
    set(state => ({
      likes: state.likes.filter(l => !(l.target_type === targetType && l.target_id === targetId))
    }));

    try {
      const { error } = await supabase
        .from('likes')
        .delete()
        .eq('user_id', userId)
        .eq('target_type', targetType)
        .eq('target_id', targetId);

      if (error) {
        console.error('取消点赞失败:', error.message);
        // 回滚本地状态
        if (targetLike) {
          set({ likes: [...previousLikes] });
        }
        return false;
      }
      return true;
    } catch (err) {
      console.error('取消点赞出错:', err);
      // 回滚本地状态
      if (targetLike) {
        set({ likes: [...previousLikes] });
      }
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