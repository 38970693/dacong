// Static export mode: exclude from static generation
export const dynamic = 'force-static';

// AI 动态 - 资讯流数据源
// 读取 hot_news_raw（HN / Reddit / RSS 等爬虫写入），兼容有无 is_ai_related 列的两种 schema
import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
);

export async function GET(request: NextRequest) {
  try {
    const sp = request.nextUrl.searchParams;

    const limit = Math.min(Math.max(Number(sp.get('limit')) || 30, 1), 100);
    const days = Math.min(Math.max(Number(sp.get('days')) || 7, 1), 30);
    const source = sp.get('source');
    const aiOnly = sp.get('aiOnly') === 'true';
    const sort = sp.get('sort') === 'hot' ? 'score' : 'fetched_at';

    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();

    // 多取一些，过滤后再截断到 limit
    let query = supabase
      .from('hot_news_raw')
      .select('*')
      .gte('fetched_at', since)
      .order(sort, { ascending: false })
      .limit(limit * 3);

    if (source) {
      query = query.eq('source', source);
    }

    const { data, error } = await query;
    if (error) throw error;

    // is_ai_related 在部分环境的 schema 里不存在：
    // 字段缺失时（undefined）不做过滤，降级为返回全部，而不是空列表
    let rows = data ?? [];
    if (aiOnly) {
      rows = rows.filter((r: Record<string, unknown>) => r.is_ai_related !== false);
    }

    // X / Bluesky 优先：社交源整体提到最前，各来源内部保持后端返回的时间/热度顺序。
    // Array.sort 自 ES2019 起保证稳定，同 rank 的元素不会被打乱。
    const PRIORITY_SOURCES = new Set(['X', 'Bluesky']);
    rows.sort((a, b) => {
      const ra = PRIORITY_SOURCES.has(a.source) ? 0 : 1;
      const rb = PRIORITY_SOURCES.has(b.source) ? 0 : 1;
      return ra - rb;
    });

    return NextResponse.json({
      success: true,
      data: rows.slice(0, limit),
      meta: { total: rows.length, days, sort, aiOnly, xFirst: true },
    });
  } catch (err) {
    console.error('[dynamics/news]', err);
    return NextResponse.json(
      { success: false, data: [], error: 'Failed to fetch news' },
      { status: 200 },
    );
  }
}
