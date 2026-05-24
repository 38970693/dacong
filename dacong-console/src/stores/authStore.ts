/**
 * 认证 Store - 使用 Supabase Auth 管理用户登录状态
 */
import { create } from 'zustand';
import { createClient, SupabaseClient, User } from '@supabase/supabase-js';
import { persist } from 'zustand/middleware';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  throw new Error('NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY must be configured');
}

const supabase = createClient(supabaseUrl, supabaseKey);

// 认证状态
interface AuthState {
  user: User | null;
  isLoading: boolean;
  isInitialized: boolean;
  error: string | null;
}

interface AuthStore extends AuthState {
  // 初始化 - 检查当前会话
  initialize: () => Promise<void>;
  // 邮箱密码登录
  signInWithEmail: (email: string, password: string) => Promise<{ success: boolean; error?: string }>;
  // 注册
  signUp: (email: string, password: string) => Promise<{ success: boolean; error?: string }>;
  // OAuth 第三方登录
  signInWithOAuth: (provider: 'google' | 'facebook') => Promise<void>;
  // 退出登录
  signOut: () => Promise<void>;
  // 获取当前用户
  getUser: () => User | null;
  // 获取 Supabase 客户端（供其他 store 使用）
  getSupabase: () => SupabaseClient;
  // 重置错误
  clearError: () => void;
  // 是否已认证（computed）
  isAuthenticated: boolean;
}

export const useAuthStore = create<AuthStore>()(
  persist(
    (set, get) => ({
      user: null,
      isLoading: false,
      isInitialized: false,
      error: null,

      // computed
      get isAuthenticated() {
        return !!get().user;
      },

      initialize: async () => {
        if (get().isInitialized) return;

        set({ isLoading: true });
        try {
          // 获取当前会话
          const { data: { session }, error } = await supabase.auth.getSession();

          if (error) {
            console.error('初始化会话失败:', error.message);
            set({ user: null, isLoading: false, isInitialized: true });
            return;
          }

          set({
            user: session?.user ?? null,
            isLoading: false,
            isInitialized: true
          });

          // 监听认证状态变化
          supabase.auth.onAuthStateChange((event, session) => {
            set({ user: session?.user ?? null });
          });
        } catch (err) {
          console.error('初始化认证失败:', err);
          set({ user: null, isLoading: false, isInitialized: true });
        }
      },

      signInWithEmail: async (email: string, password: string) => {
        set({ isLoading: true, error: null });

        try {
          const { data, error } = await supabase.auth.signInWithPassword({
            email,
            password
          });

          if (error) {
            set({ error: error.message, isLoading: false });
            return { success: false, error: error.message };
          }

          set({ user: data.user, isLoading: false });
          return { success: true };
        } catch (err) {
          const message = err instanceof Error ? err.message : '登录失败';
          set({ error: message, isLoading: false });
          return { success: false, error: message };
        }
      },

      signUp: async (email: string, password: string) => {
        set({ isLoading: true, error: null });

        try {
          const { data, error } = await supabase.auth.signUp({
            email,
            password,
            options: {
              emailRedirectTo: `${window.location.origin}/auth/callback`
            }
          });

          if (error) {
            set({ error: error.message, isLoading: false });
            return { success: false, error: error.message };
          }

          set({ user: data.user, isLoading: false });
          return { success: true };
        } catch (err) {
          const message = err instanceof Error ? err.message : '注册失败';
          set({ error: message, isLoading: false });
          return { success: false, error: message };
        }
      },

      signInWithOAuth: async (provider: 'google' | 'facebook') => {
        set({ isLoading: true, error: null });

        try {
          const { error } = await supabase.auth.signInWithOAuth({
            provider,
            options: {
              redirectTo: `${window.location.origin}/auth/callback`
            }
          });

          if (error) {
            set({ error: error.message, isLoading: false });
          }
        } catch (err) {
          const message = err instanceof Error ? err.message : '第三方登录失败';
          set({ error: message, isLoading: false });
        }
      },

      signOut: async () => {
        set({ isLoading: true });
        try {
          await supabase.auth.signOut();
          set({ user: null, isLoading: false });
        } catch (err) {
          console.error('退出登录失败:', err);
          set({ isLoading: false });
        }
      },

      getUser: () => get().user,

      getSupabase: () => supabase,

      clearError: () => set({ error: null })
    }),
    {
      name: 'dacong-auth', // localStorage key
      partialize: (state) => ({ user: state.user })
    }
  )
);