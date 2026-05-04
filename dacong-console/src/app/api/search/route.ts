import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const query = searchParams.get('q') || '';
    const type = searchParams.get('type') || 'all';

    if (!query || query.length < 2) {
      return NextResponse.json({ success: true, data: { results: [], total: 0 } });
    }

    const startTime = Date.now();
    const results: any[] = [];

    // 搜索帖子
    if (type === 'all' || type === 'posts') {
      const { data: posts } = await supabase
        .from('posts')
        .select('id, title, content, source, created_at')
        .textSearch('title', query, { type: 'websearch' })
        .limit(10);

      if (posts) {
        results.push(...posts.map(p => ({
          type: 'post' as const,
          id: p.id,
          title: p.title,
          summary: p.content?.slice(0, 100) + '...' || '',
          score: 1,
        })));
      }
    }

    // 搜索评测
    if (type === 'all' || type === 'reviews') {
      const { data: reviews } = await supabase
        .from('reviews')
        .select('id, title, summary, model_name, rating')
        .textSearch('title', query, { type: 'websearch' })
        .eq('status', 'published')
        .limit(10);

      if (reviews) {
        results.push(...reviews.map(r => ({
          type: 'review' as const,
          id: r.id,
          title: r.title,
          summary: r.summary || '',
          score: r.rating,
        })));
      }
    }

    // 搜索模型
    if (type === 'all' || type === 'models') {
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

    const took_ms = Date.now() - startTime;

    return NextResponse.json({
      success: true,
      data: { results, total: results.length, took_ms }
    });
  } catch (error) {
    console.error('Search API error:', error);
    return NextResponse.json({ success: false, error: 'Search failed' }, { status: 500 });
  }
}