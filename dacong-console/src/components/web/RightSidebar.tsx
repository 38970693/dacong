'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { AINewsItem } from '@/types/dynamics';

export function RightSidebar() {
  const [items, setItems] = useState<AINewsItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [failed, setFailed] = useState(false);
  useEffect(() => {
    const controller = new AbortController();
    fetch('/api/dynamics/news?sort=selected&days=7&limit=30', { signal: controller.signal, cache: 'no-store' })
      .then(async (response) => {
        if (!response.ok) throw new Error('Load failed');
        const body = await response.json();
        setItems(body.data ?? []);
      })
      .catch(() => { if (!controller.signal.aborted) setFailed(true); })
      .finally(() => { if (!controller.signal.aborted) setLoading(false); });
    return () => controller.abort();
  }, []);
  const sources = new Map<string, number>();
  for (const item of items) {
    for (const source of new Set(item.ai_news_sources?.map((entry) => entry.source) ?? [])) {
      sources.set(source, (sources.get(source) ?? 0) + 1);
    }
  }
  return (
    <aside className="w-80 shrink-0 p-4 sticky top-16 h-[calc(100vh-64px)] overflow-y-auto hidden xl:block">
      <div className="rounded-2xl border border-[var(--border)] bg-[var(--background)] p-5 mb-4">
        <h3 className="font-semibold mb-4">🔥 近 7 日精选</h3>
        {loading && <p className="text-sm text-[var(--text-muted)]">加载中…</p>}
        {failed && <p className="text-sm text-[var(--text-muted)]">暂时无法加载精选动态</p>}
        {!loading && !failed && !items.length && <p className="text-sm text-[var(--text-muted)]">近 7 天暂无精选动态</p>}
        <ol className="space-y-4">
          {items.slice(0, 5).map((item, index) => (
            <li key={item.id} className="flex gap-3">
              <span className="font-bold text-[var(--primary)]">{index + 1}</span>
              <Link href={`/web/dynamics/${item.id}`} className="text-sm hover:text-[var(--primary)]">
                <p className="font-medium line-clamp-2">{item.title_zh?.trim() || item.title}</p>
                <p className="mt-1 text-xs text-[var(--text-muted)]">{item.ai_news_sources?.[0]?.source} · {item.published_at?.slice(0, 10)}</p>
              </Link>
            </li>
          ))}
        </ol>
      </div>
      <div className="rounded-2xl border border-[var(--border)] bg-[var(--background)] p-5 mb-4">
        <h3 className="font-semibold mb-3">资讯来源</h3>
        <p className="text-xs text-[var(--text-muted)] mb-3">按当前近 7 天精选列表统计，最多 30 条</p>
        <ul className="space-y-2 text-sm">
          {[...sources].sort((a, b) => b[1] - a[1]).map(([source, count]) => (
            <li key={source} className="flex justify-between gap-2"><span>{source}</span><span className="text-[var(--text-muted)]">{count} 条</span></li>
          ))}
        </ul>
      </div>
      <Link href="/web/digests" className="block rounded-2xl border border-[var(--border)] p-5 hover:border-[var(--primary)]">
        <h3 className="font-semibold">📋 每日 AI 摘要 →</h3>
        <p className="mt-2 text-sm text-[var(--text-muted)]">每天北京时间 08:00，阅读过去 24 小时的精选动态。</p>
      </Link>
    </aside>
  );
}
