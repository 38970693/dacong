'use client';

import { useEffect, useState } from 'react';

interface NewsItem {
  id: string | number;
  source: string;
  title: string;
  url: string;
  summary?: string;
  author?: string;
  score?: number;
  fetched_at?: string;
}

function timeAgo(iso?: string): string {
  if (!iso) return '';
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return '刚刚';
  if (mins < 60) return `${mins} 分钟前`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours} 小时前`;
  return `${Math.floor(hours / 24)} 天前`;
}

export function NewsFeed() {
  const [items, setItems] = useState<NewsItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [sort, setSort] = useState<'time' | 'hot'>('time');

  useEffect(() => {
    let cancelled = false;
    setLoading(true);

    fetch(`/api/dynamics/news?sort=${sort}&limit=30&days=7`)
      .then((r) => r.json())
      .then((j) => {
        if (!cancelled) setItems(j.data ?? []);
      })
      .catch(() => {
        if (!cancelled) setItems([]);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [sort]);

  return (
    <div>
      <div className="flex items-center gap-2 px-4 py-3">
        {(['time', 'hot'] as const).map((s) => (
          <button
            key={s}
            onClick={() => setSort(s)}
            className={`px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${
              sort === s
                ? 'bg-[var(--primary)] text-white'
                : 'border border-[var(--border)] text-[var(--text-secondary)]'
            }`}
          >
            {s === 'time' ? '🕒 按时间' : '🔥 按热度'}
          </button>
        ))}
      </div>

      {loading && (
        <div className="px-4 py-8 text-center text-sm text-[var(--text-muted)]">加载中…</div>
      )}

      {!loading && items.length === 0 && (
        <div className="px-4 py-8 text-center text-sm text-[var(--text-muted)]">
          暂无资讯。确认爬虫已运行并向 hot_news_raw 写入数据。
        </div>
      )}

      <ul className="divide-y divide-[var(--border)]">
        {items.map((item) => (
          <li key={item.id} className="px-4 py-3 hover:bg-[var(--surface-hover)] transition-colors">
            <a href={item.url} target="_blank" rel="noopener noreferrer" className="block">
              <div className="flex items-center gap-2 mb-1">
                <span className="px-1.5 py-0.5 rounded text-[10px] font-medium bg-[var(--surface)] text-[var(--text-secondary)] border border-[var(--border)]">
                  {item.source}
                </span>
                {typeof item.score === 'number' && item.score > 0 && (
                  <span className="text-[10px] text-[var(--text-muted)]">▲ {item.score}</span>
                )}
                <span className="text-[10px] text-[var(--text-muted)] ml-auto">
                  {timeAgo(item.fetched_at)}
                </span>
              </div>
              <h3 className="text-sm font-medium text-[var(--foreground)] line-clamp-2">
                {item.title}
              </h3>
              {item.summary && (
                <p className="mt-1 text-xs text-[var(--text-muted)] line-clamp-2">{item.summary}</p>
              )}
            </a>
          </li>
        ))}
      </ul>
    </div>
  );
}
