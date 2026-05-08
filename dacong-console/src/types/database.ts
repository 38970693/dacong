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

// 评测文章 (新版本)
export interface ReviewArticle {
  id: string;
  title: string;
  slug: string;
  content: string;
  summary: string | null;
  author_name: string;
  author_avatar: string | null;
  cover_image: string | null;
  tags: string[];
  tools_mentioned: string[];
  views: number;
  likes: number;
  published: boolean;
  published_at: string | null;
  created_at: string;
  updated_at: string;
}

// 评测文章创建/更新 DTO
export type ReviewArticleInput = Omit<ReviewArticle, 'id' | 'views' | 'likes' | 'created_at' | 'updated_at'>;
export type ReviewArticleUpdate = Partial<Omit<ReviewArticle, 'id' | 'created_at'>>;

// =============================================
// v2.0 新增类型
// =============================================

// AI 模型
export interface Model {
  id: string;
  name: string;
  provider: string;
  category: string;
  description: string | null;
  icon: string | null;
  score: number;
  change: number;
  context_window: number | null;
  pricing_input: number | null;
  pricing_output: number | null;
  website_url: string | null;
  api_endpoint: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// 评测文章
export interface Review {
  id: string;
  model_id: string | null;
  model_name: string;
  title: string;
  summary: string | null;
  content: string;
  reviewer: string;
  rating: number;
  review_type: '深度评测' | '对比测试' | '专项测试' | '用户评测';
  tags: string[];
  likes: number;
  comments_count: number;
  is_featured: boolean;
  status: 'draft' | 'published' | 'archived';
  created_at: string;
  updated_at: string;
}

// 标签
export interface Tag {
  id: string;
  name: string;
  slug: string;
  color: string;
  post_count: number;
  created_at: string;
}

// 评论
export interface Comment {
  id: string;
  target_type: 'post' | 'review';
  target_id: string;
  user_id: string;
  content: string;
  parent_id: string | null;
  likes: number;
  created_at: string;
  updated_at: string;
  user_email?: string;  // 从 profiles join 得到的邮箱
  // 关联数据
  user?: {
    id: string;
    username: string;
    avatar: string | null;
  };
  replies?: Comment[];
}

// 收藏
export interface Favorite {
  id: string;
  user_id: string;
  target_type: 'post' | 'review' | 'model';
  target_id: string;
  created_at: string;
}

// 关注
export interface Follow {
  id: string;
  follower_id: string;
  following_id: string;
  created_at: string;
}

// 搜索结果
export interface SearchResult {
  type: 'post' | 'review' | 'model';
  id: string;
  title: string;
  summary: string;
  score: number;
  source?: string;
  created_at?: string;
}

// 搜索响应
export interface SearchResponse {
  query: string;
  results: SearchResult[];
  total: number;
  took_ms: number;
}