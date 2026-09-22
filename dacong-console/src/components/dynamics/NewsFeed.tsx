'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { AINewsItem, CATEGORY_LABELS, NewsCategory, TIER_LABELS } from '@/types/dynamics';

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
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [sort, setSort] = useState<'selected' | 'latest'>('selected');
  const [category, setCategory] = useState<'' | NewsCategory>('');

  useEffect(() => {
    const controller = new AbortController();
    setLoading(true);
    setError('');
    const query = new URLSearchParams({ sort, limit: '30' });
    if (category) query.set('category', category);
    fetch(`/api/dynamics/news?${query}`, { signal: controller.signal, cache: 'no-store' })
      .then(async (response) => {
        const body = await response.json();
        if (!response.ok) throw new Error(body.error || '加载失败');
        setItems(body.data ?? []);
      })
      .catch((reason) => {
        if (reason.name !== 'AbortError') setError(reason.message || '加载失败');
      })
      .finally(() => setLoading(false));
    return () => controller.abort();
  }, [sort, category]);

  return (
    <div>
      <div className="flex gap-2 px-4 py-3 overflow-x-auto border-b border-[var(--border)]">
        {CATEGORIES.map((item) => (
          <button key={item.value || 'all'} onClick={() => setCategory(item.value)}
            className={`px-3 py-1.5 rounded-full text-xs whitespace-nowrap ${category === item.value ? 'bg-[var(--primary)] text-white' : 'border border-[var(--border)] text-[var(--text-secondary)]'}`}>
            {item.label}
          </button>
        ))}
      </div>
      <div className="flex gap-2 px-4 py-3">
        {(['selected', 'latest'] as const).map((value) => (
          <button key={value} onClick={() => setSort(value)}
            className={`px-3 py-1.5 rounded-full text-xs font-medium ${sort === value ? 'bg-[var(--primary)] text-white' : 'border border-[var(--border)] text-[var(--text-secondary)]'}`}>
            {value === 'selected' ? '✨ 精选' : '🕒 最新'}
          </button>
        ))}
      </div>

      {loading && <div className="px-4 py-10 text-center text-sm text-[var(--text-muted)]">加载中…</div>}
      {!loading && error && <div className="mx-4 my-6 rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-700">{error}</div>}
      {!loading && !error && items.length === 0 && <div className="px-4 py-10 text-center text-sm text-[var(--text-muted)]">暂无符合发布标准的 AI 动态</div>}

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
                <h2 className="font-semibold leading-snug text-[var(--foreground)]">{item.title}</h2>
                {item.summary && <p className="mt-2 text-sm leading-relaxed text-[var(--text-secondary)] line-clamp-3">{item.summary}</p>}
                <p className="mt-2 text-[10px] text-[var(--text-muted)]">规则整理 · 质量分 {item.quality_score}</p>
              </Link>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
