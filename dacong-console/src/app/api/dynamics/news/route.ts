export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

const CATEGORIES = new Set(['model', 'developer_tool', 'open_source', 'research', 'industry']);

export async function GET(request: NextRequest) {
  try {
    const params = request.nextUrl.searchParams;
    const limit = Math.min(Math.max(Number(params.get('limit')) || 30, 1), 100);
    const sort = params.get('sort') === 'latest' ? 'latest' : 'selected';
    const category = params.get('category');
    const source = params.get('source');
    const cursor = params.get('cursor');
    const supabase = getSupabaseAdmin();

    let sourceIds: string[] | null = null;
    if (source) {
      const { data, error } = await supabase
        .from('ai_news_sources')
        .select('news_item_id')
        .ilike('source', source);
      if (error) throw error;
      sourceIds = [...new Set((data ?? []).map((row) => row.news_item_id))];
      if (!sourceIds.length) return NextResponse.json({ success: true, data: [], meta: { nextCursor: null } });
    }

    let query = supabase
      .from('ai_news_items')
      .select('*,ai_news_sources(source,url,original_title,source_published_at,is_primary)')
      .eq('status', 'published');
    if (category && CATEGORIES.has(category)) query = query.eq('category', category);
    if (sourceIds) query = query.in('id', sourceIds);
    if (cursor) {
      if (sort === 'selected') {
        const separator = cursor.indexOf('|');
        const score = Number(cursor.slice(0, separator));
        const publishedAt = cursor.slice(separator + 1);
        if (separator < 1 || !Number.isFinite(score) || !publishedAt) {
          return NextResponse.json({ success: false, error: '游标无效' }, { status: 400 });
        }
        query = query.or(
          `importance_score.lt.${score},and(importance_score.eq.${score},published_at.lt.${publishedAt})`,
        );
      } else {
        query = query.lt('published_at', cursor);
      }
    }
    query = sort === 'selected'
      ? query.order('importance_score', { ascending: false }).order('published_at', { ascending: false })
      : query.order('published_at', { ascending: false });

    const { data, error } = await query.limit(limit);
    if (error) throw error;
    const rows = data ?? [];
    return NextResponse.json({
      success: true,
      data: rows,
      meta: {
        total: rows.length,
        sort,
        nextCursor: rows.length === limit
          ? sort === 'selected'
            ? `${rows.at(-1)?.importance_score}|${rows.at(-1)?.published_at}`
            : rows.at(-1)?.published_at ?? null
          : null,
      },
    }, { headers: { 'Cache-Control': 'no-store' } });
  } catch (error) {
    console.error('[dynamics/news]', error);
    return NextResponse.json({ success: false, data: [], error: 'AI 动态服务暂时不可用' }, { status: 503 });
  }
}
