'use client';

import { useState, useEffect } from 'react';

// 平台类型
type Platform = 'swebench' | 'arena' | 'artificial-analysis' | 'aiping';

// Tab 配置
const platforms: { id: Platform; label: string; icon: string }[] = [
  { id: 'swebench', label: 'SWE-bench', icon: '🔧' },
  { id: 'arena', label: 'Arena.ai', icon: '🏟️' },
  { id: 'artificial-analysis', label: 'Artificial Analysis', icon: '📊' },
  { id: 'aiping', label: 'AI Ping', icon: '🎯' },
];

// 通用表格列配置
const columnConfigs: Record<Platform, { key: string; label: string; sortable: boolean; align: 'left' | 'right' }[]> = {
  swebench: [
    { key: 'rank', label: '#', sortable: true, align: 'center' },
    { key: 'model_name', label: '模型', sortable: true, align: 'left' },
    { key: 'company', label: '公司', sortable: true, align: 'left' },
    { key: 'elo_score', label: 'ELO', sortable: true, align: 'right' },
    { key: 'pass_rate', label: '通过率', sortable: true, align: 'right' },
    { key: 'instance_count', label: '实例数', sortable: true, align: 'right' },
  ],
  arena: [
    { key: 'rank', label: '#', sortable: true, align: 'center' },
    { key: 'model_name', label: '模型', sortable: true, align: 'left' },
    { key: 'company', label: '公司', sortable: true, align: 'left' },
    { key: 'elo_score', label: 'ELO', sortable: true, align: 'right' },
    { key: 'confidence_interval', label: '置信区间', sortable: false, align: 'left' },
    { key: 'vote_count', label: '票数', sortable: true, align: 'right' },
  ],
  'artificial-analysis': [
    { key: 'rank', label: '#', sortable: true, align: 'center' },
    { key: 'model_name', label: '模型', sortable: true, align: 'left' },
    { key: 'company', label: '公司', sortable: true, align: 'left' },
    { key: 'overall_rank', label: '排名', sortable: true, align: 'right' },
    { key: 'speed_score', label: '速度分', sortable: true, align: 'right' },
    { key: 'cost_score', label: '成本分', sortable: true, align: 'right' },
    { key: 'price_per_million_tokens', label: '价格/M', sortable: true, align: 'right' },
    { key: 'context_window', label: '上下文', sortable: true, align: 'right' },
  ],
  aiping: [
    { key: 'rank', label: '#', sortable: true, align: 'center' },
    { key: 'model_name', label: '模型', sortable: true, align: 'left' },
    { key: 'company', label: '公司', sortable: true, align: 'left' },
    { key: 'overall_score', label: '综合分', sortable: true, align: 'right' },
  ],
};

// Mock 数据
const mockData: Record<Platform, Record<string, unknown>[]> = {
  swebench: [
    { model_name: 'claude-3.5-sonnet-20241022', company: 'Anthropic', elo_score: 1820, pass_rate: 49.2, instance_count: 2739, category: 'standard' },
    { model_name: 'gpt-4o-2024-11-20', company: 'OpenAI', elo_score: 1756, pass_rate: 45.3, instance_count: 2739, category: 'standard' },
    { model_name: 'deepseek-v2.5', company: 'DeepSeek', elo_score: 1721, pass_rate: 42.1, instance_count: 2739, category: 'standard' },
    { model_name: 'gemini-2.0-flash-exp', company: 'Google', elo_score: 1689, pass_rate: 39.8, instance_count: 2739, category: 'standard' },
    { model_name: 'qwen2.5-72b-instruct', company: 'Alibaba', elo_score: 1654, pass_rate: 36.5, instance_count: 2739, category: 'standard' },
  ],
  arena: [
    { model_name: 'claude-3.5-sonnet-20241022', company: 'Anthropic', elo_score: 1427, confidence_interval: '±6', vote_count: 8952, category: 'general' },
    { model_name: 'gpt-4o-2024-11-20', company: 'OpenAI', elo_score: 1394, confidence_interval: '±5', vote_count: 8721, category: 'general' },
    { model_name: 'gemini-exp-1121', company: 'Google', elo_score: 1368, confidence_interval: '±6', vote_count: 7234, category: 'general' },
    { model_name: 'deepseek-v2.5', company: 'DeepSeek', elo_score: 1345, confidence_interval: '±7', vote_count: 6542, category: 'general' },
    { model_name: 'o1-preview', company: 'OpenAI', elo_score: 1334, confidence_interval: '±8', vote_count: 5123, category: 'general' },
  ],
  'artificial-analysis': [
    { model_name: 'claude-3.5-sonnet-20241022', company: 'Anthropic', overall_rank: 1, speed_score: 86, cost_score: 72, price_per_million_tokens: 3.0, context_window: 200000 },
    { model_name: 'gpt-4o-2024-11-20', company: 'OpenAI', overall_rank: 2, speed_score: 82, cost_score: 68, price_per_million_tokens: 2.5, context_window: 128000 },
    { model_name: 'gemini-2.0-flash-exp', company: 'Google', overall_rank: 3, speed_score: 95, cost_score: 85, price_per_million_tokens: 0.25, context_window: 1000000 },
    { model_name: 'deepseek-v2.5', company: 'DeepSeek', overall_rank: 4, speed_score: 78, cost_score: 92, price_per_million_tokens: 0.5, context_window: 128000 },
    { model_name: 'qwen2.5-72b-instruct', company: 'Alibaba', overall_rank: 5, speed_score: 72, cost_score: 88, price_per_million_tokens: 0.6, context_window: 128000 },
  ],
  aiping: [
    { model_name: 'claude-3.5-sonnet-20241022', company: 'Anthropic', overall_score: 97.5, dimension_scores: { intelligence: 98, creativity: 95, safety: 99 } },
    { model_name: 'gpt-4o-2024-11-20', company: 'OpenAI', overall_score: 96.2, dimension_scores: { intelligence: 97, creativity: 96, safety: 95 } },
    { model_name: 'gemini-2.0-flash-exp', company: 'Google', overall_score: 95.8, dimension_scores: { intelligence: 96, creativity: 94, safety: 97 } },
    { model_name: 'deepseek-v2.5', company: 'DeepSeek', overall_score: 94.3, dimension_scores: { intelligence: 95, creativity: 93, safety: 95 } },
    { model_name: 'qwen2.5-72b-instruct', company: 'Alibaba', overall_score: 92.1, dimension_scores: { intelligence: 93, creativity: 91, safety: 92 } },
  ],
};

export default function AIRankingsPage() {
  const [activePlatform, setActivePlatform] = useState<Platform>('swebench');
  const [data, setData] = useState<Record<string, unknown>[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [sortKey, setSortKey] = useState<string | null>(null);
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');

  // 加载数据
  useEffect(() => {
    const loadData = async () => {
      setLoading(true);
      try {
        // 尝试从 API 获取
        const res = await fetch(`/api/rankings/${activePlatform}`);
        if (res.ok) {
          const json = await res.json();
          if (json.data?.length > 0) {
            setData(json.data);
            setLoading(false);
            return;
          }
        }
        // 降级到 Mock 数据
        setData(mockData[activePlatform] || []);
      } catch {
        setData(mockData[activePlatform] || []);
      } finally {
        setLoading(false);
      }
    };
    loadData();
  }, [activePlatform]);

  // 过滤和排序
  const filteredData = data.filter((item) =>
    (item.model_name as string)?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (item.company as string)?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const sortedData = sortKey
    ? [...filteredData].sort((a, b) => {
        const aVal = a[sortKey];
        const bVal = b[sortKey];
        if (aVal == null) return 1;
        if (bVal == null) return -1;
        const cmp = aVal < bVal ? -1 : aVal > bVal ? 1 : 0;
        return sortOrder === 'asc' ? cmp : -cmp;
      })
    : filteredData;

  // 添加排名
  const displayData = sortedData.map((item, idx) => ({ ...item, rank: idx + 1 }));

  const handleSort = (key: string) => {
    if (sortKey === key) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortKey(key);
      setSortOrder('desc');
    }
  };

  const columns = columnConfigs[activePlatform];

  return (
    <div className="pb-16 md:pb-0">
      {/* 页面标题 */}
      <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        <h1 className="text-lg font-bold text-[var(--foreground)] flex items-center gap-2">
          <span>📈</span>
          <span>AI 模型评测榜单</span>
        </h1>
        <p className="text-xs text-[var(--text-muted)] hidden md:block">多平台客观评测 · 综合参考</p>
      </div>

      {/* Tab 导航 */}
      <div className="px-4 md:px-5 py-3 border-b border-[var(--border)] bg-white">
        <div className="flex gap-2 overflow-x-auto">
          {platforms.map((platform) => (
            <button
              key={platform.id}
              onClick={() => setActivePlatform(platform.id)}
              className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all shrink-0 flex items-center gap-1.5 ${
                activePlatform === platform.id
                  ? 'bg-[var(--foreground)] text-white'
                  : 'bg-white border border-[var(--border)] text-[var(--text-secondary)] hover:border-[var(--foreground)]'
              }`}
            >
              <span>{platform.icon}</span>
              <span>{platform.label}</span>
            </button>
          ))}
        </div>
      </div>

      {/* 搜索栏 */}
      <div className="px-4 md:px-5 py-3 border-b border-[var(--border)]">
        <input
          type="text"
          placeholder="搜索模型或公司..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full px-4 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg text-sm focus:outline-none focus:border-[var(--primary)]"
        />
      </div>

      {/* 数据表格 */}
      <div className="overflow-x-auto">
        <table className="w-full min-w-[600px]">
          <thead>
            <tr className="bg-[var(--background)] border-b border-[var(--border)]">
              {columns.map((col) => (
                <th
                  key={col.key}
                  onClick={() => col.sortable && handleSort(col.key)}
                  className={`px-4 py-3 text-xs font-medium text-[var(--text-muted)] uppercase tracking-wider ${
                    col.align === 'right' ? 'text-right' : 'text-left'
                  } ${col.sortable ? 'cursor-pointer hover:text-[var(--foreground)]' : ''}`}
                >
                  {col.label}
                  {col.sortable && sortKey === col.key && (
                    <span className="ml-1">{sortOrder === 'asc' ? '↑' : '↓'}</span>
                  )}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-[var(--border)]">
            {loading ? (
              <tr>
                <td colSpan={columns.length} className="px-4 py-8 text-center">
                  <div className="flex items-center justify-center gap-2 text-[var(--text-muted)]">
                    <div className="w-5 h-5 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin"></div>
                    <span>加载中...</span>
                  </div>
                </td>
              </tr>
            ) : displayData.length === 0 ? (
              <tr>
                <td colSpan={columns.length} className="px-4 py-8 text-center text-[var(--text-muted)]">
                  暂无数据
                </td>
              </tr>
            ) : (
              displayData.map((row, idx) => (
                <tr
                  key={idx}
                  className="hover:bg-[var(--background)] transition-colors"
                >
                  {columns.map((col) => (
                    <td
                      key={col.key}
                      className={`px-4 py-3 text-sm ${
                        col.align === 'right' ? 'text-right' : 'text-left'
                      }`}
                    >
                      {col.key === 'rank' ? (
                        <span className={`inline-flex items-center justify-center w-6 h-6 rounded-full text-xs font-bold ${
                          idx < 3 ? 'bg-amber-100 text-amber-700' : 'bg-[var(--background)] text-[var(--text-muted)]'
                        }`}>
                          {row.rank as number}
                        </span>
                      ) : col.key === 'model_name' ? (
                        <span className="font-medium text-[var(--foreground)]">
                          {row.model_name as string}
                        </span>
                      ) : col.key === 'elo_score' || col.key === 'overall_score' || col.key === 'pass_rate' ? (
                        <span className="font-semibold text-[var(--primary)]">
                          {row[col.key] != null ? String(row[col.key]) : '-'}
                        </span>
                      ) : (
                        <span className="text-[var(--text-secondary)]">
                          {row[col.key] != null ? String(row[col.key]) : '-'}
                        </span>
                      )}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* 底部提示 */}
      <div className="px-4 md:px-5 py-4 text-center text-xs text-[var(--text-muted)] border-t border-[var(--border)]">
        数据来源：{platforms.find(p => p.id === activePlatform)?.label} · 每日凌晨自动更新
      </div>
    </div>
  );
}