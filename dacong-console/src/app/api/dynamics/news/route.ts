export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

const CATEGORIES = new Set(['model', 'developer_tool', 'open_source', 'research', 'industry']);

type NewsCursor = { publishedAt: string; score?: number; id?: string };

function validDate(value: unknown): value is string {
  if (typeof value !== 'string' || !/^\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01])T(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?(?:Z|[+-](?:[01]\d|2[0-3]):[0-5]\d)$/.test(value)) return false;
  return Number.isFinite(Date.parse(value))
    && new Date(`${value.slice(0, 10)}T00:00:00Z`).toISOString().slice(0, 10) === value.slice(0, 10);
}

function validScore(value: unknown): value is number {
  return typeof value === 'number' && Number.isInteger(value) && value >= 0 && value <= 100;
}

function parseCursor(value: string, sort: 'selected' | 'latest'): NewsCursor | null {
  if (sort === 'latest' && validDate(value)) return { publishedAt: value };
  if (sort === 'selected' && /^\d{1,3}\|/.test(value)) {
    const [score, publishedAt] = value.split('|');
    return validScore(Number(score)) && validDate(publishedAt) && value.split('|').length === 2
      ? { score: Number(score), publishedAt } : null;
  }
  if (value.length > 1024 || !/^[A-Za-z0-9_-]+$/.test(value)) return null;
  try {
    const buffer = Buffer.from(value, 'base64url');
    if (buffer.toString('base64url') !== value) return null;
    const cursor = JSON.parse(buffer.toString('utf8'));
    if (!cursor || cursor.v !== 1 || cursor.sort !== sort || !validDate(cursor.publishedAt)
      || typeof cursor.id !== 'string' || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(cursor.id)
      || (sort === 'selected' && !validScore(cursor.score))) return null;
    return { publishedAt: cursor.publishedAt, id: cursor.id, score: cursor.score };
  } catch {
    return null;
  }
}

export async function GET(request: NextRequest) {
  try {
    const params = request.nextUrl.searchParams;
    const limit = Math.min(Math.max(Math.trunc(Number(params.get('limit'))) || 30, 1), 100);
    const sort = params.get('sort') === 'latest' ? 'latest' : 'selected';
    const category = params.get('category');
    const source = params.get('source');
    const cursorValue = params.get('cursor');
    const q = (params.get('q') ?? '').trim().replace(/\s+/g, ' ');
    const days = params.get('days') ?? '7';
    if (!['7', '30', 'all'].includes(days)) {
      return NextResponse.json({ success: false, error: '时间范围无效' }, { status: 400 });
    }
    if (q.length > 120 || q.includes('\0')) {
      return NextResponse.json({ success: false, error: q.length > 120 ? '搜索关键词最多 120 个字符' : '搜索关键词包含无效字符' }, { status: 400 });
    }
    const cursor = cursorValue ? parseCursor(cursorValue, sort) : null;
    if (cursorValue && !cursor) {
      return NextResponse.json({ success: false, error: '游标无效' }, { status: 400 });
    }
    const supabase = getSupabaseAdmin();

    let sourceIds: string[] | null = null;
    if (source) {
      const { data, error } = await supabase
        .from('ai_news_sources')
        .select('news_item_id')
        .ilike('source', source);
      if (error) throw error;
      sourceIds = [...new Set((data ?? []).map((row) => row.news_item_id))];
      if (!sourceIds.length) return NextResponse.json({
        success: true, data: [], meta: { total: 0, sort, days, q, nextCursor: null },
      }, { headers: { 'Cache-Control': 'no-store' } });
    }

    let query = supabase
      .from('ai_news_items')
      .select('*,ai_news_sources(source,url,original_title,source_published_at,is_primary)')
      .eq('status', 'published');
    if (days !== 'all') query = query.gte('published_at', new Date(Date.now() - Number(days) * 86_400_000).toISOString());
    if (category && CATEGORIES.has(category)) query = query.eq('category', category);
    if (sourceIds) query = query.in('id', sourceIds);
    if (q) {
      // Escape the regex first, then quote the complete PostgREST value.
      const pattern = q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const value = `"${pattern.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
      query = query.or(['title', 'summary', 'title_zh', 'summary_zh'].map((field) => `${field}.imatch.${value}`).join(','));
    }
    if (cursor) {
      const { score, publishedAt, id } = cursor;
      if (sort === 'selected') {
        query = query.or(
          `importance_score.lt.${score},and(importance_score.eq.${score},published_at.lt.${publishedAt})`
            + (id ? `,and(importance_score.eq.${score},published_at.eq.${publishedAt},id.lt.${id})` : ''),
        );
      } else {
        query = id
          ? query.or(`published_at.lt.${publishedAt},and(published_at.eq.${publishedAt},id.lt.${id})`)
          : query.lt('published_at', publishedAt);
      }
    }
    query = sort === 'selected'
      ? query.order('importance_score', { ascending: false }).order('published_at', { ascending: false }).order('id', { ascending: false })
      : query.order('published_at', { ascending: false }).order('id', { ascending: false });

    const { data, error } = await query.limit(limit + 1);
    if (error) throw error;
    const rows = (data ?? []).slice(0, limit);
    const last = rows.at(-1);
    return NextResponse.json({
      success: true,
      data: rows,
      meta: {
        total: rows.length,
        sort,
        days,
        q,
        nextCursor: data && data.length > limit && last
          ? Buffer.from(JSON.stringify({
            v: 1, sort, publishedAt: last.published_at, id: last.id,
            ...(sort === 'selected' ? { score: last.importance_score } : {}),
          })).toString('base64url')
          : null,
      },
    }, { headers: { 'Cache-Control': 'no-store' } });
  } catch (error) {
    console.error('[dynamics/news]', error);
    return NextResponse.json({ success: false, data: [], error: 'AI 动态服务暂时不可用' }, { status: 503 });
  }
}
