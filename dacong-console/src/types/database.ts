/**
 * Database Types - 与 Supabase 数据库表结构对应
 */

// 爬虫原始数据
export interface RawPost {
  id: string;
  source: string;       // '36kr', 'huxiu'
  source_url: string;
  title: string;
  content: string | null;
  author: string | null;
  published_at: string | null;
  crawled_at: string;
  status: 'pending' | 'approved' | 'rejected';
}

// 审核后的内容
export interface Post {
  id: string;
  raw_post_id: string | null;
  title: string;
  content: string | null;
  source: string | null;
  source_url: string | null;
  views: number;
  likes: number;
  comments_count: number;
  created_at: string;
  updated_at: string;
}

// 用户行为记录
export interface UserAction {
  id: string;
  user_id: string;
  post_id: string;
  action_type: 'view' | 'like';
  created_at: string;
}

// 用户表
export interface User {
  id: string;
  role: 'guest' | 'user' | 'admin';
  created_at: string;
}

// 榜单缓存
export interface TrendingCache {
  id: string;
  post_id: string;
  list_type: 'hot' | 'new';
  score: number;
  rank: number;
  updated_at: string;
}

// API 响应格式
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  meta?: {
    total: number;
    page: number;
    limit: number;
    next_cursor?: string;
  };
}

// 分页参数
export interface PaginationParams {
  limit?: number;
  cursor?: string;
}

// 帖子列表响应
export interface PostsResponse {
  posts: Post[];
  next_cursor: string | null;
}

// 榜单响应
export interface TrendingResponse {
  trending: (Post & { score: number; rank: number })[];
}