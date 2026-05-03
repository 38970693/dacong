'use client';

import { useState } from 'react';

interface ModelRanking {
  rank: number;
  name: string;
  provider: string;
  category: string;
  score: number;
  change: number;
  icon: string;
}

const mockRankings: ModelRanking[] = [
  { rank: 1, name: 'Claude 3.5 Sonnet', provider: 'Anthropic', category: '综合', score: 98.5, change: 0, icon: '🧠' },
  { rank: 2, name: 'GPT-4 Turbo', provider: 'OpenAI', category: '综合', score: 97.2, change: 1, icon: '🤖' },
  { rank: 3, name: 'Gemini 1.5 Pro', provider: 'Google', category: '综合', score: 96.8, change: -1, icon: '✨' },
  { rank: 4, name: 'Llama 3.1 405B', provider: 'Meta', category: '开源', score: 94.3, change: 2, icon: '🦙' },
  { rank: 5, name: 'Qwen 2.5 72B', provider: '阿里', category: '开源', score: 93.1, change: 0, icon: '🔮' },
  { rank: 6, name: 'Mistral Large 2', provider: 'Mistral', category: '综合', score: 91.7, change: 1, icon: '🌊' },
  { rank: 7, name: 'Deepseek V2.5', provider: '深度求索', category: '开源', score: 90.4, change: 3, icon: '🔍' },
  { rank: 8, name: 'Command R+', provider: 'Cohere', category: 'RAG', score: 89.2, change: -1, icon: '📚' },
  { rank: 9, name: 'Yi-Large', provider: '零一万物', category: '综合', score: 88.5, change: 0, icon: 'Yi' },
  { rank: 10, name: 'GLM-4', provider: '智谱', category: '综合', score: 87.8, change: -2, icon: 'GL' },
];

const categories = ['综合', '开源', 'RAG', '代码', '数学', '多模态'];
const timeRanges = ['实时', '今日', '本周', '本月'];

export default function RankingPage() {
  const [activeCategory, setActiveCategory] = useState('综合');
  const [activeTimeRange, setActiveTimeRange] = useState('实时');

  return (
    <div className="pb-16 md:pb-0">
      {/* 页面标题 */}
      <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        <h1 className="text-lg font-bold text-[var(--foreground)] flex items-center gap-2">
          <span>🏆</span>
          <span>AI 模型榜单</span>
        </h1>
        <p className="text-xs text-[var(--text-muted)] hidden md:block">客观评测 · 实时更新 · 全面对比</p>
      </div>

      {/* 筛选栏 */}
      <div className="px-4 md:px-5 py-3 border-b border-[var(--border)]">
        {/* 时间范围 */}
        <div className="flex gap-2 mb-3 overflow-x-auto">
          {timeRanges.map((range) => (
            <button
              key={range}
              onClick={() => setActiveTimeRange(range)}
              className={`px-3 py-1.5 rounded-full text-xs font-medium whitespace-nowrap transition-all shrink-0 ${
                activeTimeRange === range
                  ? 'bg-[var(--primary)] text-white'
                  : 'bg-white border border-[var(--border)] text-[var(--text-secondary)] hover:border-[var(--primary)]'
              }`}
            >
              {range}
            </button>
          ))}
        </div>

        {/* 分类 */}
        <div className="flex gap-2 overflow-x-auto">
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => setActiveCategory(cat)}
              className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all shrink-0 ${
                activeCategory === cat
                  ? 'bg-[var(--foreground)] text-white'
                  : 'bg-white border border-[var(--border)] text-[var(--text-secondary)] hover:border-[var(--foreground)]'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      {/* TOP 3 冠军卡片 */}
      <div className="p-4 md:p-5 border-b border-[var(--border)]">
        <div className="grid grid-cols-3 gap-2 md:gap-4">
          {mockRankings.slice(0, 3).map((model, idx) => (
            <div
              key={model.rank}
              className={`relative p-3 md:p-4 rounded-2xl border transition-all ${
                idx === 0
                  ? 'bg-gradient-to-br from-amber-50 to-orange-50 border-amber-200 order-2'
                  : idx === 1
                  ? 'bg-gradient-to-br from-gray-50 to-slate-50 border-gray-200 order-1'
                  : 'bg-gradient-to-br from-amber-50 to-yellow-50 border-amber-100 order-3'
              }`}
            >
              {/* 排名标签 */}
              <div className={`absolute -top-2 -right-2 w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold ${
                idx === 0
                  ? 'bg-amber-500 text-white'
                  : idx === 1
                  ? 'bg-gray-400 text-white'
                  : 'bg-amber-600 text-white'
              }`}>
                {model.rank}
              </div>

              {/* 图标 */}
              <div className="text-2xl md:text-3xl mb-2">{model.icon}</div>

              {/* 名称 */}
              <h3 className="font-bold text-[var(--foreground)] text-xs md:text-sm leading-tight">{model.name}</h3>
              <p className="text-xs text-[var(--text-muted)]">{model.provider}</p>

              {/* 分数 */}
              <div className="mt-2 flex items-baseline gap-1">
                <span className={`text-lg md:text-2xl font-bold ${
                  idx === 0 ? 'text-amber-600' : 'text-[var(--foreground)]'
                }`}>
                  {model.score}
                </span>
                <span className="text-xs text-[var(--text-muted)]">分</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* 完整榜单 */}
      <div className="divide-y divide-[var(--border)]">
        {mockRankings.slice(3).map((model) => (
          <div
            key={model.rank}
            className="px-4 md:px-5 py-3 md:py-4 hover:bg-[var(--background)] transition-colors cursor-pointer flex items-center gap-3"
          >
            {/* 排名 */}
            <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm shrink-0 ${
              model.rank <= 5 ? 'bg-[var(--primary-light)] text-[var(--primary)]' : 'bg-[var(--background)] text-[var(--text-muted)]'
            }`}>
              {model.rank}
            </div>

            {/* 图标 */}
            <div className="text-xl shrink-0">{model.icon}</div>

            {/* 信息 */}
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2">
                <h3 className="font-semibold text-[var(--foreground)] text-sm">{model.name}</h3>
                <span className="px-1.5 py-0.5 bg-[var(--background)] text-[var(--text-muted)] text-xs rounded">
                  {model.category}
                </span>
              </div>
              <p className="text-xs text-[var(--text-muted)]">{model.provider}</p>
            </div>

            {/* 分数和变化 */}
            <div className="text-right shrink-0">
              <div className="text-lg font-bold text-[var(--foreground)]">{model.score}</div>
              <div className={`text-xs flex items-center justify-end gap-0.5 ${
                model.change > 0 ? 'text-green-500' : model.change < 0 ? 'text-red-500' : 'text-[var(--text-muted)]'
              }`}>
                {model.change > 0 && '▲'}
                {model.change < 0 && '▼'}
                {model.change !== 0 && Math.abs(model.change)}
                {model.change === 0 && '—'}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* 查看更多 */}
      <div className="p-6 md:p-8 text-center">
        <button className="px-6 py-2.5 bg-white border border-[var(--border)] text-[var(--foreground)] rounded-full text-sm font-medium hover:bg-[var(--background)] transition-all">
          查看完整榜单 →
        </button>
      </div>
    </div>
  );
}