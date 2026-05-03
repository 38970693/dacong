import { create } from 'zustand';
import { createClient } from '@supabase/supabase-js';
import type { Post, PostsResponse } from '@/types/database';

// Supabase 客户端配置（前端直接访问）
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
const supabase = createClient(supabaseUrl, supabaseKey);

// 分页配置
const DEFAULT_LIMIT = 20;
interface PostsState {
  posts: Post[];
  isLoading: boolean;
  error: string | null;
  nextCursor: string | null;
  hasMore: boolean;
}

// 榜单状态
interface TrendingState {
  hot: Post[];
  new: Post[];
  isLoading: boolean;
  error: string | null;
}

// 帖子列表 Store
interface PostsStore extends PostsState {
  fetchPosts: () => Promise<void>;
  loadMore: () => Promise<void>;
  refresh: () => Promise<void>;
  addPost: (post: Post) => void;
}

export const usePostsStore = create<PostsStore>((set, get) => ({
  posts: [],
  isLoading: false,
  error: null,
  nextCursor: null,
  hasMore: true,

  fetchPosts: async () => {
    set({ isLoading: true, error: null });
    try {
      // 直连 Supabase，绕过 Vercel API
      const { data: posts, error, count } = await supabase
        .from('posts')
        .select('id, raw_post_id, title, content, source, source_url, views, likes, comments_count, created_at, updated_at', { count: 'exact' })
        .eq('status', 'approved')
        .order('created_at', { ascending: false })
        .limit(DEFAULT_LIMIT);

      if (error) throw error;

      // 生成下一个 cursor
      let nextCursor: string | null = null;
      if (posts && posts.length === DEFAULT_LIMIT) {
        const lastPost = posts[posts.length - 1];
        nextCursor = `${lastPost.created_at}_${lastPost.id}`;
      }

      set({
        posts: posts || [],
        nextCursor,
        hasMore: !!nextCursor,
        isLoading: false
      });
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Unknown error', isLoading: false });
    }
  },

  loadMore: async () => {
    const { nextCursor, isLoading, hasMore, posts } = get();
    if (!nextCursor || isLoading || !hasMore) return;

    set({ isLoading: true });
    try {
      // cursor 格式：timestamp_id
      const [timestamp, id] = nextCursor.split('_');
      const { data: morePosts, error } = await supabase
        .from('posts')
        .select('id, raw_post_id, title, content, source, source_url, views, likes, comments_count, created_at, updated_at')
        .eq('status', 'approved')
        .lt('created_at', timestamp)
        .lt('id', id)
        .order('created_at', { ascending: false })
        .limit(DEFAULT_LIMIT);

      if (error) throw error;

      // 生成下一个 cursor
      let newCursor: string | null = null;
      if (morePosts && morePosts.length === DEFAULT_LIMIT) {
        const lastPost = morePosts[morePosts.length - 1];
        newCursor = `${lastPost.created_at}_${lastPost.id}`;
      }

      set({
        posts: [...posts, ...(morePosts || [])],
        nextCursor: newCursor,
        hasMore: !!newCursor,
        isLoading: false
      });
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Unknown error', isLoading: false });
    }
  },

  refresh: async () => {
    set({ posts: [], nextCursor: null, hasMore: true });
    await get().fetchPosts();
  },

  addPost: (post) => set((state) => ({
    posts: [post, ...state.posts]
  }))
}));

// 榜单 Store
interface TrendingStore extends TrendingState {
  fetchHot: () => Promise<void>;
  fetchNew: () => Promise<void>;
  refreshAll: () => Promise<void>;
}

export const useTrendingStore = create<TrendingStore>((set, get) => ({
  hot: [],
  new: [],
  isLoading: false,
  error: null,

  fetchHot: async () => {
    try {
      // 直连 Supabase
      const { data, error } = await supabase
        .from('posts')
        .select('id, raw_post_id, title, content, source, source_url, views, likes, comments_count, created_at, updated_at')
        .eq('status', 'approved')
        .order('views', { ascending: false })
        .limit(20);

      if (error) throw error;
      set({ hot: data || [] });
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  },

  fetchNew: async () => {
    try {
      // 直连 Supabase
      const { data, error } = await supabase
        .from('posts')
        .select('id, raw_post_id, title, content, source, source_url, views, likes, comments_count, created_at, updated_at')
        .eq('status', 'approved')
        .order('created_at', { ascending: false })
        .limit(20);

      if (error) throw error;
      set({ new: data || [] });
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  },

  refreshAll: async () => {
    set({ isLoading: true, error: null });
    await Promise.all([get().fetchHot(), get().fetchNew()]);
    set({ isLoading: false });
  }
}));

// 用户 Store
interface UserState {
  isAuthenticated: boolean;
  userId: string | null;
  role: 'guest' | 'user' | 'admin';
}

interface UserStore extends UserState {
  setUser: (userId: string | null, role: 'guest' | 'user' | 'admin') => void;
  logout: () => void;
}

export const useUserStore = create<UserStore>((set) => ({
  isAuthenticated: false,
  userId: null,
  role: 'guest',

  setUser: (userId, role) => set({
    isAuthenticated: !!userId,
    userId,
    role
  }),

  logout: () => set({
    isAuthenticated: false,
    userId: null,
    role: 'guest'
  })
}));