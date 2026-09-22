'use client';

import Link from 'next/link';
import { use, useEffect, useState } from 'react';
import { AINewsItem, CATEGORY_LABELS, DailyDigest } from '@/types/dynamics';

type DigestDetail = DailyDigest & { items: Array<{ rank: number; category: string; ai_news_items: AINewsItem }> };

export default function DigestDetailPage({ params }: { params: Promise<{ date: string }> }) {
  const { date } = use(params);
  const [digest, setDigest] = useState<DigestDetail | null>(null);
  const [error, setError] = useState('');
  useEffect(() => {
    fetch(`/api/dynamics/digests/${date}`)
      .then(async (response) => {
        const body = await response.json();
        if (!response.ok) throw new Error(body.error || '加载失败');
        setDigest(body.data);
      })
      .catch((reason) => setError(reason.message || '加载失败'));
  }, [date]);
  if (error) return <div className="p-6 text-red-600">{error}</div>;
  if (!digest) return <div className="p-6 text-[var(--text-muted)]">加载中…</div>;
  return (
    <div className="p-4 md:p-6">
      <Link href="/web/digests" className="text-sm text-[var(--primary)]">← 返回日报</Link>
      <h1 className="mt-5 text-2xl font-bold">{digest.title}</h1>
      <p className="mt-2 text-[var(--text-secondary)]">{digest.intro}</p>
      <ol className="mt-6 divide-y divide-[var(--border)]">
        {digest.items.map(({ rank, ai_news_items: item }) => (
          <li key={item.id} className="py-4">
            <Link href={`/web/dynamics/${item.id}`}>
              <p className="text-xs text-[var(--text-muted)]">#{rank} · {CATEGORY_LABELS[item.category]}</p>
              <h2 className="mt-1 font-semibold">{item.title}</h2>
              <p className="mt-2 text-sm text-[var(--text-secondary)]">{item.summary}</p>
            </Link>
          </li>
        ))}
      </ol>
    </div>
  );
}
