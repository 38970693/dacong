'use client';

import { useState, useEffect } from 'react';
import type { Model } from '@/types/database';

const categories = ['全部', '综合', '开源', 'RAG', '代码', '数学', '多模态'];
const timeRanges = ['实时', '今日', '本周', '本月'];

export default function RankingPage() {
  const [activeCategory, setActiveCategory] = useState('全部');
  const [activeTimeRange, setActiveTimeRange] = useState('实时');
  const [models, setModels] = useState<Model[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchModels();
  }, [activeCategory]);

  async function fetchModels() {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams({ category: activeCategory });
      const res = await fetch(`/api/models?${params}`);
      const json = await res.json();
      if (json.success) {
        setModels(json.data || []);
      } else {
        // 降级到模拟数据
        setModels(getMockModels());
      }
    } catch {
      setModels(getMockModels());
    } finally {
      setLoading(false);
    }
  }

  function getMockModels(): Model[] {
    return [
      { id: '1', name: 'Claude 3.5 Sonnet', provider: 'Anthropic', category: '综合', icon: '🧠', score: 98.5, change: 0, description: null, context_window: 200000, pricing_input: 3, pricing_output: 15, website_url: null, api_endpoint: null, is_active: true, created_at: '', updated_at: '' },
      { id: '2', name: 'GPT-4 Turbo', provider: 'OpenAI', category: '综合', icon: '🤖', score: 97.2, change: 1, description: null, context_window: 128000, pricing_input: 10, pricing_output: 30, website_url: null, api_endpoint: null, is_active: true, created_at: '', updated_at: '' },
      { id: '3', name: 'Gemini 1.5 Pro', provider: 'Google', category: '综合', icon: '✨', score: 96.8, change: -1, description: null, context_window: 1000000, pricing_input: 1.25, pricing_output: 5, website_url: null, api_endpoint: null, is_active: true, created_at: '', updated_at: '' },
      { id: '4', name: 'Llama 3.1 405B', provider: 'Meta', category: '开源', icon: '🦙', score: 94.3, change: 2, description: null, context_window: 128000, pricing_input: null, pricing_output: null, website_url: null, api_endpoint: null, is_active: true, created_at: '', updated_at: '' },
      { id: '5', name: 'Qwen 2.5 72B', provider: '阿里', category: '开源', icon: '🔮', score: 93.1, change: 0, description: null, context_window: 128000, pricing_input: 0.6, pricing_output: 1.8, website_url: null, api_endpoint: null, is_active: true, created_at: '', updated_at: '' },
      { id: '6', name: 'Mistral Large 2', provider: 'Mistral', category: '综合', icon: '🌊', score: 91.7, change: 1, description: null, context_window: 128000, pricing_input: 2, pricing_output: 6, website_url: null, api_endpoint: null, is_active: true, created_at: '', updated_at: '' },
      { id: '7', name: 'Deepseek V2.5', provider: '深度求索', category: '开源', icon: '🔍', score: 90.4, change: 3, description: null, context_window: 128000, pricing_input: 0.5, pricing_output: 1, website_url: null, api_endpoint: null, is_active: true, created_at: '', updated_at: '' },
      { id: '8', name: 'Command R+', provider: 'Cohere', category: 'RAG', icon: '📚', score: 89.2, change: -1, description: null, context_window: 128000, pricing_input: 2.5, pricing_output: 10, website_url: null, api_endpoint: null, is_active: true, created_at: '', updated_at: '' },
      { id: '9', name: 'Yi-Large', provider: '零一万物', category: '综合', icon: 'Yi', score: 88.5, change: 0, description: null, context_window: 200000, pricing_input: 3, pricing_output: 9, website_url: null, api_endpoint: null, is_active: true, created_at: '', updated_at: '' },
      { id: '10', name: 'GLM-4', provider: '智谱', category: '综合', icon: 'GL', score: 87.8, change: -2, description: null, context_window: 128000, pricing_input: 0.6, pricing_output: 1.8, website_url: null, api_endpoint: null, is_active: true, created_at: '', updated_at: '' },
    ];
  }

  const top3 = models.slice(0, 3);
  const rest = models.slice(3);

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
      {loading ? (
        <div className="p-8 flex items-center justify-center">
          <div className="w-8 h-8 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin"></div>
        </div>
      ) : (
        <div className="p-4 md:p-5 border-b border-[var(--border)]">
          <div className="grid grid-cols-3 gap-2 md:gap-4">
            {top3.map((model, idx) => (
              <div
                key={model.id}
                className={`relative p-3 md:p-4 rounded-2xl border transition-all cursor-pointer hover:scale-105 ${
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
                  {idx + 1}
                </div>

                {/* 图标 */}
                <div className="text-2xl md:text-3xl mb-2">{model.icon || '🤖'}</div>

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
      )}

      {/* 完整榜单 */}
      <div className="divide-y divide-[var(--border)]">
        {loading ? (
          <div className="p-8 text-center text-[var(--text-muted)]">加载中...</div>
        ) : rest.length === 0 ? (
          <div className="p-8 text-center text-[var(--text-muted)]">暂无数据</div>
        ) : (
          rest.map((model, idx) => (
            <div
              key={model.id}
              className="px-4 md:px-5 py-3 md:py-4 hover:bg-[var(--background)] transition-colors cursor-pointer flex items-center gap-3"
            >
              {/* 排名 */}
              <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm shrink-0 ${
                idx + 4 <= 5 ? 'bg-[var(--primary-light)] text-[var(--primary)]' : 'bg-[var(--background)] text-[var(--text-muted)]'
              }`}>
                {idx + 4}
              </div>

              {/* 图标 */}
              <div className="text-xl shrink-0">{model.icon || '🤖'}</div>

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
          ))
        )}
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