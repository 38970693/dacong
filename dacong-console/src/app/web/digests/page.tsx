'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { DailyDigest } from '@/types/dynamics';

export default function DigestsPage() {
  const [digests, setDigests] = useState<DailyDigest[]>([]);
  const [error, setError] = useState('');
  useEffect(() => {
    fetch('/api/dynamics/digests')
      .then(async (response) => {
        const body = await response.json();
        if (!response.ok) throw new Error(body.error || '加载失败');
        setDigests(body.data ?? []);
      })
      .catch((reason) => setError(reason.message || '加载失败'));
  }, []);
  return (
    <div className="p-4 md:p-6">
      <h1 className="text-xl font-bold">AI 日报</h1>
      <p className="mt-1 text-sm text-[var(--text-muted)]">每天 08:00，快速了解过去 24 小时的重要变化</p>
      {error && <p className="mt-6 text-sm text-red-600">{error}</p>}
      <div className="mt-6 space-y-3">
        {digests.map((digest) => (
          <Link key={digest.id} href={`/web/digests/${digest.digest_date}`} className="block rounded-xl border border-[var(--border)] p-4 hover:border-[var(--primary)]">
            <div className="flex items-center justify-between gap-4"><h2 className="font-semibold">{digest.title}</h2><span className="text-xs text-[var(--text-muted)]">{digest.item_count} 条</span></div>
            <p className="mt-2 text-sm text-[var(--text-secondary)]">{digest.intro}</p>
          </Link>
        ))}
        {!error && digests.length === 0 && <p className="py-10 text-center text-sm text-[var(--text-muted)]">暂无日报</p>}
      </div>
    </div>
  );
}
