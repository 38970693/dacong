/**
 * 评测文章 Store - 管理评测文章列表和详情
 */
import { create } from 'zustand';
import { createClient } from '@supabase/supabase-js';
import type { Review } from '@/types/database';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByc3prZGJkZ2ZmYmRxY2xiZ29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NzUyMDksImV4cCI6MjA5MzI1MTIwOX0.m2eElXYUlB-XHXZ8w988APQs4u1s2rn5VlIOjn2m_t0';
const supabase = createClient(supabaseUrl, supabaseKey);

type ReviewType = '全部' | '深度评测' | '对比测试' | '专项测试' | '用户评测';
type SortOption = '最新' | '评分最高' | '最热';

interface ReviewsState {
  reviews: Review[];
  currentReview: Review | null;
  isLoading: boolean;
  error: string | null;
  total: number;
}

interface ReviewsStore extends ReviewsState {
  fetchReviews: (type?: ReviewType, sort?: SortOption) => Promise<void>;
  fetchReviewById: (id: string) => Promise<Review | null>;
  createReview: (data: Omit<Review, 'id' | 'created_at' | 'updated_at' | 'likes' | 'comments_count' | 'status'>) => Promise<Review | null>;
  updateReview: (id: string, data: Partial<Review>) => Promise<boolean>;
  deleteReview: (id: string) => Promise<boolean>;
  getFeatured: () => Review | null;
}

export const useReviewsStore = create<ReviewsStore>((set, get) => ({
  reviews: [],
  currentReview: null,
  isLoading: false,
  error: null,
  total: 0,

  fetchReviews: async (type?: ReviewType, sort: SortOption = '最新') => {
    set({ isLoading: true, error: null });
    try {
      let query = supabase
        .from('reviews')
        .select('*', { count: 'exact' })
        .eq('status', 'published');

      if (type && type !== '全部') {
        query = query.eq('review_type', type);
      }

      // 排序
      switch (sort) {
        case '评分最高':
          query = query.order('rating', { ascending: false });
          break;
        case '最热':
          query = query.order('likes', { ascending: false });
          break;
        case '最新':
        default:
          query = query.order('created_at', { ascending: false });
          break;
      }

      query = query.limit(20);

      const { data, error, count } = await query;

      if (error) throw error;
      set({
        reviews: data || [],
        total: count || 0,
        isLoading: false
      });
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Failed to fetch reviews',
        isLoading: false
      });
    }
  },

  fetchReviewById: async (id: string) => {
    set({ isLoading: true, error: null, currentReview: null });
    try {
      const { data, error } = await supabase
        .from('reviews')
        .select('*')
        .eq('id', id)
        .single();

      if (error) throw error;
      set({ currentReview: data, isLoading: false });
      return data;
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Failed to fetch review',
        isLoading: false
      });
      return null;
    }
  },

  createReview: async (data) => {
    set({ isLoading: true, error: null });
    try {
      const { data: newReview, error } = await supabase
        .from('reviews')
        .insert([{ ...data, status: 'published' }])
        .select()
        .single();

      if (error) throw error;
      set(state => ({
        reviews: [newReview, ...state.reviews],
        isLoading: false
      }));
      return newReview;
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Failed to create review',
        isLoading: false
      });
      return null;
    }
  },

  updateReview: async (id: string, data: Partial<Review>) => {
    set({ isLoading: true, error: null });
    try {
      const { error } = await supabase
        .from('reviews')
        .update({ ...data, updated_at: new Date().toISOString() })
        .eq('id', id);

      if (error) throw error;

      set(state => ({
        reviews: state.reviews.map(r => r.id === id ? { ...r, ...data } : r),
        currentReview: state.currentReview?.id === id ? { ...state.currentReview, ...data } : state.currentReview,
        isLoading: false
      }));
      return true;
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Failed to update review',
        isLoading: false
      });
      return false;
    }
  },

  deleteReview: async (id: string) => {
    set({ isLoading: true, error: null });
    try {
      const { error } = await supabase
        .from('reviews')
        .delete()
        .eq('id', id);

      if (error) throw error;

      set(state => ({
        reviews: state.reviews.filter(r => r.id !== id),
        currentReview: state.currentReview?.id === id ? null : state.currentReview,
        isLoading: false
      }));
      return true;
    } catch (error) {
      set({
        error: error instanceof Error ? error.message : 'Failed to delete review',
        isLoading: false
      });
      return false;
    }
  },

  getFeatured: () => {
    const { reviews } = get();
    return reviews.find(r => r.is_featured) || reviews[0] || null;
  }
}));
