export type NewsCategory = 'model' | 'developer_tool' | 'open_source' | 'research' | 'industry';
export type SourceTier = 'official' | 'professional' | 'community';

export interface AINewsSource {
  source: string;
  url: string;
  original_title?: string;
  source_published_at?: string | null;
  is_primary: boolean;
}

export interface AINewsItem {
  id: string;
  title: string;
  summary: string;
  language: 'zh' | 'en' | 'other';
  category: NewsCategory;
  source_tier: SourceTier;
  quality_score: number;
  importance_score: number;
  published_at?: string | null;
  ai_news_sources: AINewsSource[];
}

export interface DailyDigest {
  id: string;
  digest_date: string;
  title: string;
  intro: string;
  item_count: number;
  published_at: string;
}

export const CATEGORY_LABELS: Record<NewsCategory, string> = {
  model: '模型进展',
  developer_tool: '开发工具',
  open_source: '开源项目',
  research: '研究进展',
  industry: '行业动态',
};

export const TIER_LABELS: Record<SourceTier, string> = {
  official: '官方来源',
  professional: '专业媒体',
  community: '社区动态',
};
