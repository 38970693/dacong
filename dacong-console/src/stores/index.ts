import { create } from 'zustand';
import type { Post } from '@/types/database';

// 帖子列表状态
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
      const response = await fetch('/api/posts');
      if (!response.ok) throw new Error('Failed to fetch posts');
      const data = await response.json();
      set({
        posts: data.posts || [],
        nextCursor: data.next_cursor,
        hasMore: !!data.next_cursor,
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
      const response = await fetch(`/api/posts?cursor=${nextCursor}`);
      if (!response.ok) throw new Error('Failed to load more');
      const data = await response.json();
      set({
        posts: [...posts, ...(data.posts || [])],
        nextCursor: data.next_cursor,
        hasMore: !!data.next_cursor,
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

export const useTrendingStore = create<TrendingStore>((set) => ({
  hot: [],
  new: [],
  isLoading: false,
  error: null,

  fetchHot: async () => {
    try {
      const response = await fetch('/api/trending?type=hot');
      if (!response.ok) throw new Error('Failed to fetch hot');
      const data = await response.json();
      set({ hot: data.trending || [] });
    } catch (error) {
      set({ error: error instanceof Error ? error.message : 'Unknown error' });
    }
  },

  fetchNew: async () => {
    try {
      const response = await fetch('/api/trending?type=new');
      if (!response.ok) throw new Error('Failed to fetch new');
      const data = await response.json();
      set({ new: data.trending || [] });
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