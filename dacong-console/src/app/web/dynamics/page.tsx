'use client';

import { useState } from 'react';
import { NewsFeed } from '@/components/dynamics/NewsFeed';
import { RisingList } from '@/components/dynamics/RisingList';
import { ModelPulse } from '@/components/dynamics/ModelPulse';

type ViewType = 'news' | 'rising' | 'pulse';

const VIEWS: Array<{ key: ViewType; label: string; desc: string }> = [
  { key: 'news', label: '📰 资讯流', desc: '关注模型发布、Agent 与 AI 编程、开源和研究进展' },
  { key: 'rising', label: '🚀 飙升榜', desc: '哪个仓库正在火' },
  { key: 'pulse', label: '📈 模型脉搏', desc: '哪个模型在变强' },
];

export default function DynamicsPage() {
  const [view, setView] = useState<ViewType>('news');
  const current = VIEWS.find((v) => v.key === view)!;

  return (
    <div className="min-w-0">
      <div className="sticky top-14 md:top-16 z-10 bg-[var(--background)]/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        <h1 className="text-lg font-bold text-[var(--foreground)]">AI 动态</h1>
        <p className="text-xs text-[var(--text-muted)]">{current.desc}</p>
      </div>

      <div className="flex gap-2 overflow-x-auto px-4 md:px-5 py-3 border-b border-[var(--border)]">
        {VIEWS.map((v) => (
          <button
            key={v.key}
            onClick={() => setView(v.key)}
            className={`shrink-0 whitespace-nowrap px-3 sm:px-4 py-2 rounded-full text-sm font-semibold transition-all ${
              view === v.key
                ? 'bg-[var(--primary)] text-white shadow-lg shadow-[var(--primary)]/30'
                : 'border border-[var(--border)] text-[var(--text-secondary)] hover:border-[var(--primary)] hover:text-[var(--primary)]'
            }`}
          >
            {v.label}
          </button>
        ))}
      </div>

      {view === 'news' && <NewsFeed />}
      {view === 'rising' && <RisingList />}
      {view === 'pulse' && <ModelPulse />}
    </div>
  );
}
