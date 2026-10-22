import { createClient } from '@supabase/supabase-js';
import { NextRequest } from 'next/server';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { getSupabaseAdmin } from '@/lib/supabase-admin';
import { GET } from './route';

vi.mock('@/lib/supabase-admin', () => ({ getSupabaseAdmin: vi.fn() }));

const date = '2026-10-21T08:00:00.123456+00:00';
const ids = [
  '00000000-0000-4000-8000-000000000003',
  '00000000-0000-4000-8000-000000000002',
  '00000000-0000-4000-8000-000000000001',
];
const rows = ids.map((id) => ({
  id, title: 'GPT release', summary: 'Model improvements', title_zh: '模型更新',
  summary_zh: '中文模型摘要', status: 'published', category: 'model',
  importance_score: 80, published_at: date, ai_news_sources: [],
}));
const databaseFetch = vi.fn<typeof fetch>();

function reply(data: unknown) {
  databaseFetch.mockResolvedValueOnce(new Response(JSON.stringify(data), {
    status: 200, headers: { 'Content-Type': 'application/json' },
  }));
}

function request(params: Record<string, string> = {}) {
  return GET(new NextRequest(`https://dacong.test/api/dynamics/news?${new URLSearchParams(params)}`));
}

function databaseParams(call = 0) {
  return new URL(String(databaseFetch.mock.calls[call][0])).searchParams;
}

function encode(value: unknown) {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}

beforeEach(() => {
  vi.clearAllMocks();
  vi.mocked(getSupabaseAdmin).mockReturnValue(createClient('https://database.test', 'test-key', {
    global: { fetch: databaseFetch },
    auth: { persistSession: false, autoRefreshToken: false },
  }));
});

describe('GET /api/dynamics/news', () => {
  it.each(['GPT release', '模型更新', '中文模型摘要'])(
    'searches originals and translations for %s without dropping publication filters', async (q) => {
      reply([rows[0]]);
      const response = await request({ q: `  ${q.replace(' ', '  \n ')}  `, days: '30', category: 'model' });
      expect(response.status).toBe(200);
      expect((await response.json()).meta).toEqual({ total: 1, sort: 'selected', days: '30', q, nextCursor: null });
      const filters = databaseParams();
      expect(filters.get('status')).toBe('eq.published');
      expect(filters.get('category')).toBe('eq.model');
      expect(filters.get('published_at')).toMatch(/^gte\./);
      expect(filters.getAll('or')).toEqual([
        `(${['title', 'summary', 'title_zh', 'summary_zh'].map((field) => `${field}.imatch."${q}"`).join(',')})`,
      ]);
    },
  );

  it.each([
    ['a,b', 'a,b'],
    ['a(b)', 'a\\(b\\)'],
    ['a"b', 'a"b'],
    ['a\\b', 'a\\\\b'],
    ['100%_', '100%_'],
    ['a*b.c|d+$^?', 'a\\*b\\.c\\|d\\+\\$\\^\\?'],
    ['x),status.eq.quarantined,or(title.eq.x', 'x\\),status\\.eq\\.quarantined,or\\(title\\.eq\\.x'],
  ])('treats special search text %s as a quoted literal', async (q, regex) => {
    reply([]);
    expect((await request({ q, days: 'all' })).status).toBe(200);
    const filters = databaseParams();
    const value = JSON.stringify(regex);
    expect(filters.getAll('or')).toEqual([
      `(${['title', 'summary', 'title_zh', 'summary_zh'].map((field) => `${field}.imatch.${value}`).join(',')})`,
    ]);
    expect(filters.get('status')).toBe('eq.published');
    expect(filters.has('published_at')).toBe(false);
  });

  it('does not add a search filter for whitespace and rejects excessively long keywords', async () => {
    reply([]);
    const empty = await request({ q: ' \n\t ' });
    expect((await empty.json()).meta.q).toBe('');
    expect(databaseParams().has('or')).toBe(false);
    const tooLong = await request({ q: '模'.repeat(121) });
    expect(tooLong.status).toBe(400);
    expect((await tooLong.json()).error).toContain('120');
    expect(databaseFetch).toHaveBeenCalledTimes(1);
  });

  it.each(['selected', 'latest'])('paginates %s through ties using the final row ID', async (sort) => {
    reply(rows);
    const first = await (await request({ sort, days: 'all', limit: '2', q: 'GPT' })).json();
    expect(first.data.map((row: { id: string }) => row.id)).toEqual(ids.slice(0, 2));
    expect(first.meta.total).toBe(2);
    expect(first.meta.nextCursor).toEqual(expect.any(String));
    expect(first.meta.nextCursor).not.toContain('|');
    expect(databaseParams().get('limit')).toBe('3');
    expect(databaseParams().get('order')).toBe(sort === 'selected'
      ? 'importance_score.desc,published_at.desc,id.desc' : 'published_at.desc,id.desc');

    reply([rows[2]]);
    const last = await (await request({ sort, days: 'all', limit: '2', q: 'GPT', cursor: first.meta.nextCursor })).json();
    expect(last.data.map((row: { id: string }) => row.id)).toEqual([ids[2]]);
    expect(last.meta).toEqual({ total: 1, sort, days: 'all', q: 'GPT', nextCursor: null });
    const cursorFilter = databaseParams(1).getAll('or');
    expect(cursorFilter).toContain(sort === 'selected'
      ? `(importance_score.lt.80,and(importance_score.eq.80,published_at.lt.${date}),and(importance_score.eq.80,published_at.eq.${date},id.lt.${ids[1]}))`
      : `(published_at.lt.${date},and(published_at.eq.${date},id.lt.${ids[1]}))`);
    expect(cursorFilter).toHaveLength(2);
    expect(databaseParams(1).get('status')).toBe('eq.published');
  });

  it('does not return a next cursor when the final page has exactly limit rows', async () => {
    reply(rows.slice(0, 2));
    const body = await (await request({ limit: '2' })).json();
    expect(body.data).toHaveLength(2);
    expect(body.meta.nextCursor).toBeNull();
  });

  it('retains all metadata when no items match a requested source', async () => {
    reply([]);
    const response = await request({ source: 'No source', sort: 'latest', days: 'all', q: 'model' });
    expect(await response.json()).toEqual({
      success: true, data: [], meta: { total: 0, sort: 'latest', days: 'all', q: 'model', nextCursor: null },
    });
    expect(databaseFetch).toHaveBeenCalledTimes(1);
    expect(response.headers.get('Cache-Control')).toBe('no-store');
  });

  it('combines the source, category, time, publication and search filters', async () => {
    reply([{ news_item_id: ids[0] }, { news_item_id: ids[0] }]);
    reply([rows[0]]);
    const response = await request({ source: 'OpenAI', category: 'model', days: '7', q: '模型' });
    expect(response.status).toBe(200);
    const filters = databaseParams(1);
    expect(filters.get('id')).toBe(`in.(${ids[0]})`);
    expect(filters.get('status')).toBe('eq.published');
    expect(filters.get('category')).toBe('eq.model');
    expect(filters.get('published_at')).toMatch(/^gte\./);
    expect(filters.get('or')).toContain('title_zh.imatch."模型"');
  });

  it.each([
    ['selected', `80|${date}`], ['latest', date],
  ])('accepts a valid legacy %s cursor', async (sort, cursor) => {
    reply([]);
    const response = await request({ sort, cursor, days: 'all' });
    expect(response.status).toBe(200);
    if (sort === 'latest') expect(databaseParams().get('published_at')).toBe(`lt.${date}`);
    else expect(databaseParams().get('or')).toContain(`importance_score.eq.80,published_at.lt.${date}`);
  });

  it.each([
    ['selected', '80|2026-10-20T00:00:00Z),status.eq.quarantined'],
    ['latest', '2026-10-20T00:00:00Z),status.eq.quarantined'],
    ['selected', '80|not-a-date'], ['selected', '101|2026-10-20T00:00:00Z'],
    ['latest', '2026-02-30T00:00:00Z'], ['latest', '!invalid-base64!'],
    ['selected', encode({ v: 1, sort: 'selected', score: 80, publishedAt: date, id: 'x),status.eq.quarantined' })],
    ['latest', encode({ v: 1, sort: 'selected', score: 80, publishedAt: date, id: ids[0] })],
    ['selected', encode({ v: 2, sort: 'selected', score: 80, publishedAt: date, id: ids[0] })],
    ['selected', encode({ v: 1, sort: 'selected', score: null, publishedAt: date, id: ids[0] })],
    ['latest', encode({ v: 1, sort: 'latest', publishedAt: date })],
  ])('rejects invalid %s cursor before querying the database: %s', async (sort, cursor) => {
    const response = await request({ sort, cursor, source: 'OpenAI' });
    expect(response.status).toBe(400);
    expect(await response.json()).toMatchObject({ success: false, error: '游标无效' });
    expect(databaseFetch).not.toHaveBeenCalled();
  });

  it('rejects an invalid time range', async () => {
    const response = await request({ days: '365' });
    expect(response.status).toBe(400);
    expect(databaseFetch).not.toHaveBeenCalled();
  });

  it('returns the existing friendly error if the database is unavailable', async () => {
    const errorLog = vi.spyOn(console, 'error').mockImplementation(() => {});
    databaseFetch.mockResolvedValueOnce(new Response(JSON.stringify({ message: 'database unavailable' }), { status: 500 }));
    const response = await request();
    expect(response.status).toBe(503);
    expect(await response.json()).toEqual({ success: false, data: [], error: 'AI 动态服务暂时不可用' });
    errorLog.mockRestore();
  });
});
