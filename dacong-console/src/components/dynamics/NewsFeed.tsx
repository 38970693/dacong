'use client';

import Link from 'next/link';
import { useCallback, useEffect, useRef, useState } from 'react';
import { AINewsItem, CATEGORY_LABELS, NewsCategory, TIER_LABELS } from '@/types/dynamics';
import { NewsTranslation } from './NewsTranslation';

const CATEGORIES: Array<{ value: '' | NewsCategory; label: string }> = [
  { value: '', label: '全部' },
  ...Object.entries(CATEGORY_LABELS).map(([value, label]) => ({ value: value as NewsCategory, label })),
];

function timeAgo(iso?: string | null): string {
  if (!iso) return '时间未知';
  const minutes = Math.max(0, Math.floor((Date.now() - new Date(iso).getTime()) / 60_000));
  if (minutes < 60) return `${Math.max(1, minutes)} 分钟前`;
  if (minutes < 1440) return `${Math.floor(minutes / 60)} 小时前`;
  return `${Math.floor(minutes / 1440)} 天前`;
}
export function NewsFeed() {
  const [items, setItems] = useState<AINewsItem[]>([]);
  const [loading, setLoading] = useState<'first' | 'more' | null>('first');
  const [error, setError] = useState<{ message: string; cursor?: string } | null>(null);
  const [nextCursor, setNextCursor] = useState<string | null>(null);
  const [filters, setFilters] = useState({ sort: 'selected' as 'selected' | 'latest', category: '' as '' | NewsCategory, days: '7', q: '' });
  const [searchInput, setSearchInput] = useState('');
  const activeRequest = useRef<AbortController | null>(null);

  const loadPage = useCallback(async (cursor?: string, reset = false) => {
    if (cursor && activeRequest.current && !activeRequest.current.signal.aborted) return;
    activeRequest.current?.abort();
    const controller = new AbortController();
    activeRequest.current = controller;
    setLoading(cursor ? 'more' : 'first');
    setError(null);
    if (reset) {
      setItems([]);
      setNextCursor(null);
    }
    const query = new URLSearchParams({ sort: filters.sort, days: filters.days, limit: '30' });
    if (filters.category) query.set('category', filters.category);
    if (filters.q) query.set('q', filters.q);
    if (cursor) query.set('cursor', cursor);
    try {
      const response = await fetch(`/api/dynamics/news?${query}`, { signal: controller.signal, cache: 'no-store' });
      const body = await response.json();
      if (!response.ok) throw new Error(body.error || '加载失败，请稍后重试');
      if (controller.signal.aborted || activeRequest.current !== controller) return;
      const page: AINewsItem[] = body.data ?? [];
      setItems((previous) => cursor ? [...new Map([...previous, ...page].map((item) => [item.id, item])).values()] : page);
      setNextCursor(body.meta?.nextCursor ?? null);
    } catch (reason) {
      if (!controller.signal.aborted && activeRequest.current === controller) {
        setError({ message: reason instanceof Error ? reason.message : '加载失败，请稍后重试', cursor });
      }
    } finally {
      if (!controller.signal.aborted && activeRequest.current === controller) {
        activeRequest.current = null;
        setLoading(null);
      }
    }
  }, [filters]);

  useEffect(() => {
    void loadPage(undefined, true);
    return () => activeRequest.current?.abort();
  }, [loadPage]);

  function updateFilters(update: Partial<typeof filters>) {
    if (Object.entries(update).every(([key, value]) => filters[key as keyof typeof filters] === value)) return;
    activeRequest.current?.abort();
    setFilters({ ...filters, ...update });
  }

  return (
    <div>
      <form role="search" onSubmit={(event) => {
        event.preventDefault();
        const q = searchInput.trim();
        setSearchInput(q);
        updateFilters({ q });
      }} className="flex gap-2 px-4 pt-3">
        <input type="search" aria-label="搜索 AI 动态" placeholder="搜索标题或摘要" maxLength={120}
          value={searchInput} onChange={(event) => setSearchInput(event.target.value)}
          className="min-w-0 flex-1 min-h-11 rounded-lg border border-[var(--border)] bg-[var(--background)] px-3 text-sm text-[var(--foreground)]" />
        <button type="submit" className="shrink-0 min-h-11 rounded-lg bg-[var(--primary)] px-3 text-sm text-white">搜索</button>
        {(searchInput || filters.q) && <button type="button" onClick={() => { setSearchInput(''); updateFilters({ q: '' }); }}
          className="shrink-0 min-h-11 rounded-lg border border-[var(--border)] px-3 text-sm text-[var(--text-secondary)]">清空</button>}
      </form>
      <div className="flex gap-2 px-4 py-3 overflow-x-auto border-b border-[var(--border)]">
        {CATEGORIES.map((item) => (
          <button key={item.value || 'all'} onClick={() => updateFilters({ category: item.value })} aria-pressed={filters.category === item.value}
            className={`shrink-0 min-h-10 px-3 py-1.5 rounded-full text-xs whitespace-nowrap ${filters.category === item.value ? 'bg-[var(--primary)] text-white' : 'border border-[var(--border)] text-[var(--text-secondary)]'}`}>
            {item.label}
          </button>
        ))}
      </div>
      <div className="flex flex-wrap items-center gap-2 px-4 py-3">
        {(['selected', 'latest'] as const).map((value) => (
          <button key={value} onClick={() => updateFilters({ sort: value })} aria-pressed={filters.sort === value}
            className={`shrink-0 min-h-10 whitespace-nowrap px-3 py-1.5 rounded-full text-xs font-medium ${filters.sort === value ? 'bg-[var(--primary)] text-white' : 'border border-[var(--border)] text-[var(--text-secondary)]'}`}>
            {value === 'selected' ? '✨ 精选' : '🕒 最新'}
          </button>
        ))}
        <select aria-label="动态时间范围" value={filters.days} onChange={(event) => updateFilters({ days: event.target.value })}
          className="ml-auto max-w-full min-h-10 rounded-lg border border-[var(--border)] bg-[var(--background)] px-2 py-1.5 text-xs text-[var(--text-secondary)]">
          <option value="7">近 7 天</option><option value="30">近 30 天</option><option value="all">全部时间</option>
        </select>
        <button type="button" onClick={() => void loadPage()} disabled={!!loading}
          className="shrink-0 min-h-10 rounded-lg border border-[var(--border)] px-3 text-xs text-[var(--primary)] disabled:opacity-50">刷新</button>
      </div>

      {loading === 'first' && <div role="status" className="px-4 py-6 text-center text-sm text-[var(--text-muted)]">加载中…</div>}
      {error && <div role="alert" className="mx-4 my-4 rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">
        <p>{error.message}</p>
        <button type="button" onClick={() => void loadPage(error.cursor)} disabled={!!loading}
          className="mt-2 min-h-11 rounded-lg border border-red-300 px-4 disabled:opacity-50">重试</button>
      </div>}
      {!loading && !error && items.length === 0 && <div className="px-4 py-10 text-center text-sm text-[var(--text-muted)]">{filters.q ? '未找到匹配的 AI 动态' : '暂无符合发布标准的 AI 动态'}</div>}

      <ul className="divide-y divide-[var(--border)]">
        {items.map((item) => {
          const primary = item.ai_news_sources?.find((source) => source.is_primary) ?? item.ai_news_sources?.[0];
          return (
            <li key={item.id} className="px-4 py-4 hover:bg-[var(--surface-hover)] transition-colors">
              <Link href={`/web/dynamics/${item.id}`} className="block">
                <div className="mb-2 flex flex-wrap items-center gap-2 text-[10px] text-[var(--text-muted)]">
                  <span className="rounded border border-[var(--border)] px-1.5 py-0.5">{CATEGORY_LABELS[item.category]}</span>
                  <span>{TIER_LABELS[item.source_tier]}</span>
                  {primary && <span>{primary.source}</span>}
                  <span>{timeAgo(item.published_at)}</span>
                </div>
              </Link>
              <NewsTranslation item={item} href={`/web/dynamics/${item.id}`} />
              <div className="mt-2 flex items-center gap-3 text-xs text-[var(--text-muted)]">
                {primary && <a href={primary.url} target="_blank" rel="noopener noreferrer" className="text-[var(--primary)] hover:underline">阅读原文 ↗</a>}
                {item.ai_news_sources?.length > 1 && <span>{item.ai_news_sources.length} 个来源</span>}
              </div>
            </li>
          );
        })}
      </ul>
      {nextCursor && !error && <div className="px-4 py-5 text-center">
        <button type="button" onClick={() => void loadPage(nextCursor)} disabled={!!loading}
          className="min-h-11 rounded-lg border border-[var(--border)] px-6 text-sm text-[var(--primary)] disabled:opacity-50">
          {loading === 'more' ? '加载中…' : '加载更多'}
        </button>
      </div>}
      {!loading && !error && items.length > 0 && !nextCursor && <p className="px-4 py-5 text-center text-xs text-[var(--text-muted)]">已显示全部资讯</p>}
    </div>
  );
}
