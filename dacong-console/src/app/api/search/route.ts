// Static export mode: exclude from static generation
export const dynamic = 'force-static';

import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

// 支持的数据来源
const SOURCES = ['36kr', 'huxiu', 'jiemian', 'ithome', 'pinpai', 'leike', 'aisharenet'] as const;
type Source = typeof SOURCES[number];

// 时间范围选项
type TimeRange = 'today' | 'this_week' | 'this_month' | 'all';

// 获取时间范围的起始日期
function getTimeRangeStart(range: TimeRange): string | null {
  const now = new Date();
  switch (range) {
    case 'today': {
      const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      return start.toISOString();
    }
    case 'this_week': {
      const start = new Date(now);
      start.setDate(now.getDate() - 7);
      return start.toISOString();
    }
    case 'this_month': {
      const start = new Date(now.getFullYear(), now.getMonth(), 1);
      return start.toISOString();
    }
    case 'all':
    default:
      return null;
  }
}

// 搜索结果接口
interface SearchResult {
  type: 'post' | 'review' | 'model';
  id: string;
  title: string;
  summary: string;
  score: number;
  source?: string;
  created_at?: string;
}

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const query = searchParams.get('q') || '';
    const type = searchParams.get('type') || 'all';
    const sources = searchParams.get('sources')?.split(',').filter(Boolean) || [];
    const timeRange = (searchParams.get('time_range') || 'all') as TimeRange;

    // 如果查询为空且没有筛选条件，返回空结果
    if (!query && sources.length === 0 && timeRange !== 'all') {
      return NextResponse.json({ success: true, data: { results: [], total: 0 } });
    }

    const startTime = Date.now();
    const results: SearchResult[] = [];

    // 计算时间范围起始日期
    const timeStart = getTimeRangeStart(timeRange);

    // 搜索帖子（支持来源和时间筛选）
    if (type === 'all' || type === 'posts') {
      let postQuery = supabase
        .from('posts')
        .select('id, title, content, source, source_url, views, likes, created_at')
        .eq('status', 'approved');

      // 添加来源筛选
      if (sources.length > 0) {
        postQuery = postQuery.in('source', sources);
      }

      // 添加时间范围筛选
      if (timeStart) {
        postQuery = postQuery.gte('created_at', timeStart);
      }

      // 添加搜索条件
      if (query && query.length >= 2) {
        // 尝试使用全文搜索，如果失败则使用 ilike
        try {
          postQuery = postQuery.textSearch('title', query, { type: 'websearch' });
        } catch {
          // 回退到 ilike 搜索
          postQuery = postQuery.or(`title.ilike.%${query}%,content.ilike.%${query}%`);
        }
      }

      const { data: posts } = await postQuery.limit(20);

      if (posts) {
        results.push(...posts.map(p => ({
          type: 'post' as const,
          id: p.id,
          title: p.title,
          summary: p.content?.slice(0, 120) + (p.content && p.content.length > 120 ? '...' : '') || '',
          score: p.views + p.likes * 10, // 根据热度计算得分
          source: p.source,
          created_at: p.created_at,
        })));
      }
    }

    // 搜索评测（支持来源和时间筛选）
    if (type === 'all' || type === 'reviews') {
      let reviewQuery = supabase
        .from('reviews')
        .select('id, title, summary, model_name, rating, created_at')
        .eq('status', 'published');

      // 添加时间范围筛选
      if (timeStart) {
        reviewQuery = reviewQuery.gte('created_at', timeStart);
      }

      // 添加搜索条件
      if (query && query.length >= 2) {
        try {
          reviewQuery = reviewQuery.textSearch('title', query, { type: 'websearch' });
        } catch {
          reviewQuery = reviewQuery.or(`title.ilike.%${query}%,summary.ilike.%${query}%`);
        }
      }

      const { data: reviews } = await reviewQuery.limit(10);

      if (reviews) {
        results.push(...reviews.map(r => ({
          type: 'review' as const,
          id: r.id,
          title: r.title,
          summary: r.summary || `${r.model_name} 的评测文章`,
          score: r.rating,
          created_at: r.created_at,
        })));
      }
    }

    // 搜索模型（不支持来源和时间筛选，仅按名称搜索）
    if (type === 'all' || type === 'models') {
      if (query && query.length >= 2) {
        const { data: models } = await supabase
          .from('models')
          .select('id, name, provider, description, score')
          .or(`name.ilike.%${query}%,provider.ilike.%${query}%`)
          .eq('is_active', true)
          .limit(10);

        if (models) {
          results.push(...models.map(m => ({
            type: 'model' as const,
            id: m.id,
            title: m.name,
            summary: m.description || `${m.provider} 的模型`,
            score: m.score,
          })));
        }
      }
    }

    // 按得分排序
    results.sort((a, b) => b.score - a.score);

    const took_ms = Date.now() - startTime;

    return NextResponse.json({
      success: true,
      data: {
        results,
        total: results.length,
        took_ms,
        filters: {
          sources: sources.length > 0 ? sources : null,
          time_range: timeRange,
        }
      }
    });
  } catch (err) {
    console.error('Search API error:', err);
    return NextResponse.json({ success: false, error: 'Search failed' }, { status: 500 });
  }
}
