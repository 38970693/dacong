// 数据库类型定义
export interface RawPost {
  id: string;
  source: '36kr' | 'huxiu';
  source_url: string;
  title: string;
  content: string | null;
  author: string | null;
  published_at: string | null;
  crawled_at: string;
  status: 'pending' | 'approved' | 'rejected';
}

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
  status: 'pending' | 'approved' | 'rejected';
  created_at: string;
  updated_at: string;
}

export interface TrendingCache {
  id: string;
  post_id: string;
  list_type: 'hot' | 'new';
  score: number;
  rank: number;
  updated_at: string;
}

export interface CrawlResult {
  source: string;
  posts: CrawledPost[];
  success: boolean;
  error?: string;
  crawledCount: number;
}

export interface CrawledPost {
  title: string;
  content: string | null;
  source_url: string;
  author: string | null;
  published_at: string | null;
}