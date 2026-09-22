'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { createSupabaseClient } from '@/utils/supabase/client';

interface ReviewItem {
  id: string;
  title: string;
  category: string;
  source_tier: string;
  quality_score: number;
  status: 'published' | 'quarantined' | 'withdrawn';
}

interface SourceSetting {
  source: string;
  tier: 'official' | 'professional' | 'community';
  default_category: string | null;
  enabled: boolean;
}

export default function DynamicsAdminPage() {
  const [status, setStatus] = useState<ReviewItem['status']>('quarantined');
  const [items, setItems] = useState<ReviewItem[]>([]);
  const [sources, setSources] = useState<SourceSetting[]>([]);
  const [error, setError] = useState('');
  const [processing, setProcessing] = useState(false);
  const supabase = useMemo(() => createSupabaseClient(), []);

  const load = useCallback(async () => {
    const { data: { session } } = await supabase.auth.getSession();
    const response = await fetch(`/api/admin/dynamics?status=${status}`, {
      headers: session ? { Authorization: `Bearer ${session.access_token}` } : {},
    });
    const body = await response.json();
    if (!response.ok) throw new Error(body.error || '加载失败');
    setItems(body.data ?? []);
  }, [status, supabase]);

  const loadSources = useCallback(async () => {
    const { data: { session } } = await supabase.auth.getSession();
    const response = await fetch('/api/admin/dynamics/sources', {
      headers: session ? { Authorization: `Bearer ${session.access_token}` } : {},
    });
    const body = await response.json();
    if (!response.ok) throw new Error(body.error || '来源加载失败');
    setSources(body.data ?? []);
  }, [supabase]);

  useEffect(() => { load().catch((reason) => setError(reason.message)); }, [load]);
  useEffect(() => { loadSources().catch((reason) => setError(reason.message)); }, [loadSources]);

  async function update(id: string, action: 'withdraw' | 'restore') {
    const { data: { session } } = await supabase.auth.getSession();
    const response = await fetch(`/api/admin/dynamics/${id}/${action}`, {
      method: 'POST', headers: session ? { Authorization: `Bearer ${session.access_token}` } : {},
    });
    if (!response.ok) throw new Error((await response.json()).error || '操作失败');
    await load();
  }

  async function processQueue() {
    setProcessing(true);
    setError('');
    try {
      const { data: { session } } = await supabase.auth.getSession();
      const response = await fetch('/api/admin/dynamics/process', {
        method: 'POST',
        headers: session ? { Authorization: `Bearer ${session.access_token}` } : {},
      });
      const body = await response.json();
      if (!response.ok) throw new Error(body.error || '处理失败');
      await load();
    } finally {
      setProcessing(false);
    }
  }

  async function toggleSource(setting: SourceSetting) {
    const { data: { session } } = await supabase.auth.getSession();
    const response = await fetch(`/api/admin/dynamics/sources/${encodeURIComponent(setting.source)}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        ...(session ? { Authorization: `Bearer ${session.access_token}` } : {}),
      },
      body: JSON.stringify({ enabled: !setting.enabled }),
    });
    const body = await response.json();
    if (!response.ok) throw new Error(body.error || '更新失败');
    await loadSources();
  }

  return (
    <div className="p-6">
      <div className="flex items-center justify-between gap-4">
        <h1 className="text-2xl font-bold">AI 动态管理</h1>
        <button onClick={() => processQueue().catch((reason) => setError(reason.message))} disabled={processing} className="rounded-lg bg-blue-600 px-3 py-2 text-sm text-white disabled:opacity-60">
          {processing ? '处理中…' : '处理采集队列'}
        </button>
      </div>
      <div className="mt-5 flex gap-2">
        {(['quarantined', 'published', 'withdrawn'] as const).map((value) => (
          <button key={value} onClick={() => setStatus(value)} className={`rounded-lg px-3 py-2 text-sm ${status === value ? 'bg-blue-600 text-white' : 'bg-gray-100'}`}>{value}</button>
        ))}
      </div>
      {error && <p className="mt-4 text-red-600">{error}</p>}
      <div className="mt-5 space-y-3">
        {items.map((item) => (
          <div key={item.id} className="rounded-xl border p-4">
            <div className="flex items-start justify-between gap-4">
              <div><h2 className="font-medium">{item.title}</h2><p className="mt-1 text-xs text-gray-500">{item.category} · {item.source_tier} · 质量分 {item.quality_score}</p></div>
              {item.status === 'published'
                ? <button onClick={() => update(item.id, 'withdraw').catch((reason) => setError(reason.message))} className="text-sm text-red-600">撤回</button>
                : <button onClick={() => update(item.id, 'restore').catch((reason) => setError(reason.message))} className="text-sm text-blue-600">发布</button>}
            </div>
          </div>
        ))}
      </div>
      <h2 className="mt-10 text-lg font-semibold">来源开关</h2>
      <div className="mt-3 grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
        {sources.map((source) => (
          <button key={source.source} onClick={() => toggleSource(source).catch((reason) => setError(reason.message))} className="flex items-center justify-between rounded-lg border px-3 py-2 text-left text-sm">
            <span><strong>{source.source}</strong><span className="ml-2 text-gray-500">{source.tier}</span></span>
            <span className={source.enabled ? 'text-green-600' : 'text-gray-400'}>{source.enabled ? '已启用' : '已停用'}</span>
          </button>
        ))}
      </div>
    </div>
  );
}
