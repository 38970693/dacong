'use client';

import Link from 'next/link';
import { use, useEffect, useState } from 'react';
import { AINewsItem, CATEGORY_LABELS, TIER_LABELS } from '@/types/dynamics';
import { NewsTranslation } from '@/components/dynamics/NewsTranslation';

export default function DynamicsDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const [item, setItem] = useState<AINewsItem | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    fetch(`/api/dynamics/news/${id}`, { cache: 'no-store' })
      .then(async (response) => {
        const body = await response.json();
        if (!response.ok) throw new Error(body.error || '加载失败');
        setItem(body.data);
      })
      .catch((reason) => setError(reason.message || '加载失败'));
  }, [id]);

  if (error) return <div className="p-6 text-red-600">{error}</div>;
  if (!item) return <div className="p-6 text-[var(--text-muted)]">加载中…</div>;

  return (
    <article className="p-5 md:p-8">
      <Link href="/web/dynamics" className="text-sm text-[var(--primary)]">← 返回 AI 动态</Link>
      <div className="mt-6 flex flex-wrap gap-2 text-xs text-[var(--text-muted)]">
        <span>{CATEGORY_LABELS[item.category]}</span><span>·</span><span>{TIER_LABELS[item.source_tier]}</span>
      </div>
      <NewsTranslation key={item.id} item={item} detail />
      <h2 className="mt-8 font-semibold">来源</h2>
      <ul className="mt-3 space-y-3">
        {item.ai_news_sources.map((source) => (
          <li key={source.url} className="rounded-xl border border-[var(--border)] p-3">
            <a href={source.url} target="_blank" rel="noopener noreferrer" className="text-sm [overflow-wrap:anywhere] text-[var(--primary)] hover:underline">
              {source.source}：{source.original_title || item.title} ↗
            </a>
          </li>
        ))}
      </ul>
    </article>
  );
}
