'use client';

import { useState, useEffect, Suspense, useCallback } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import { EmptyState } from '@/components/ui/EmptyState';
import type { SearchResult } from '@/types/database';

// 支持的数据来源
const SOURCES = [
  { value: '36kr', label: '36Kr' },
  { value: 'huxiu', label: '虎嗅' },
  { value: 'jiemian', label: '界面新闻' },
  { value: 'ithome', label: 'IT之家' },
] as const;

// 时间范围选项
const TIME_RANGES = [
  { value: 'all', label: '全部时间' },
  { value: 'today', label: '今天' },
  { value: 'this_week', label: '本周' },
  { value: 'this_month', label: '本月' },
] as const;

type Source = typeof SOURCES[number]['value'];
type TimeRange = typeof TIME_RANGES[number]['value'];

interface SearchFilters {
  sources: Source[];
  timeRange: TimeRange;
}

function SearchContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const initialQuery = searchParams.get('q') || '';
  const initialSources = (searchParams.get('sources')?.split(',').filter(Boolean) || []) as Source[];
  const initialTimeRange = (searchParams.get('time_range') || 'all') as TimeRange;

  const [inputValue, setInputValue] = useState(initialQuery);
  const [query, setQuery] = useState(initialQuery);
  const [results, setResults] = useState<SearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [tookMs, setTookMs] = useState(0);
  const [filters, setFilters] = useState<SearchFilters>({
    sources: initialSources,
    timeRange: initialTimeRange,
  });
  const [showFilters, setShowFilters] = useState(false);

  // 执行搜索
  const performSearch = useCallback(async (searchQuery: string, searchFilters: SearchFilters) => {
    const params = new URLSearchParams();
    if (searchQuery) {
      params.set('q', searchQuery);
    }
    if (searchFilters.sources.length > 0) {
      params.set('sources', searchFilters.sources.join(','));
    }
    if (searchFilters.timeRange !== 'all') {
      params.set('time_range', searchFilters.timeRange);
    }

    // 更新 URL
    const newUrl = params.toString() ? `/web/search?${params.toString()}` : '/web/search';
    router.push(newUrl, { scroll: false });

    // 如果没有搜索条件且没有筛选条件，返回空
    if (!searchQuery && searchFilters.sources.length === 0 && searchFilters.timeRange !== 'all') {
      setResults([]);
      setTookMs(0);
      return;
    }

    setLoading(true);
    try {
      const res = await fetch(`/api/search?${params.toString()}`);
      const json = await res.json();
      if (json.success) {
        setResults(json.data.results || []);
        setTookMs(json.data.took_ms || 0);
      }
    } catch {
      setResults([]);
    } finally {
      setLoading(false);
    }
  }, [router]);

  // 初始加载或参数变化时执行搜索
  useEffect(() => {
    if (initialQuery || initialSources.length > 0 || initialTimeRange !== 'all') {
      setQuery(initialQuery);
      setInputValue(initialQuery);
      performSearch(initialQuery, { sources: initialSources, timeRange: initialTimeRange });
    }
  }, [initialQuery, initialSources, initialTimeRange, performSearch]);

  // 处理搜索提交
  const handleSearch = () => {
    setQuery(inputValue);
    performSearch(inputValue, filters);
  };

  // 处理键盘事件
  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSearch();
    }
  };

  // 切换来源筛选
  const toggleSource = (source: Source) => {
    const newSources = filters.sources.includes(source)
      ? filters.sources.filter(s => s !== source)
      : [...filters.sources, source];
    const newFilters = { ...filters, sources: newSources };
    setFilters(newFilters);
    performSearch(query, newFilters);
  };

  // 设置时间范围
  const setTimeRange = (timeRange: TimeRange) => {
    const newFilters = { ...filters, timeRange };
    setFilters(newFilters);
    performSearch(query, newFilters);
  };

  // 清除所有筛选
  const clearFilters = () => {
    setFilters({ sources: [], timeRange: 'all' });
    performSearch(query, { sources: [], timeRange: 'all' });
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'post': return '📄';
      case 'review': return '📝';
      case 'model': return '🤖';
      default: return '📌';
    }
  };

  const getTypeLabel = (type: string) => {
    switch (type) {
      case 'post': return '资讯';
      case 'review': return '评测';
      case 'model': return '模型';
      default: return type;
    }
  };

  const getTypePath = (type: string, id: string) => {
    switch (type) {
      case 'post': return `/web/post/${id}`;
      case 'review': return `/web/review/${id}`;
      case 'model': return `/web/ranking`;
      default: return '#';
    }
  };

  const hasActiveFilters = filters.sources.length > 0 || filters.timeRange !== 'all';

  return (
    <div className="pb-16 md:pb-0">
      {/* 页面标题和搜索框 */}
      <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        <h1 className="text-lg font-bold text-[var(--foreground)] flex items-center gap-2 mb-3">
          <span>🔍</span>
          <span>搜索</span>
        </h1>

        {/* 搜索输入框 */}
        <div className="flex gap-2">
          <div className="relative flex-1">
            <input
              type="text"
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="搜索 AI 模型、资讯、评测..."
              className="w-full px-4 py-2.5 pl-10 bg-[var(--background)] border border-[var(--border)] rounded-full text-sm text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)] focus:ring-2 focus:ring-[var(--primary)]/20 transition-all"
            />
            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-[var(--text-muted)]">
              🔍
            </span>
            {inputValue && (
              <button
                onClick={() => { setInputValue(''); setQuery(''); setResults([]); }}
                className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 rounded-full bg-[var(--text-muted)] text-white flex items-center justify-center text-xs hover:bg-[var(--foreground)] transition-colors"
              >
                ✕
              </button>
            )}
          </div>
          <button
            onClick={handleSearch}
            className="px-5 py-2.5 gradient-btn text-white rounded-full font-medium hover:opacity-90 transition-opacity"
          >
            搜索
          </button>
        </div>

        {/* 筛选按钮 */}
        <div className="flex items-center gap-2 mt-3">
          <button
            onClick={() => setShowFilters(!showFilters)}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${
              showFilters || hasActiveFilters
                ? 'bg-[var(--primary)] text-white'
                : 'bg-[var(--background)] text-[var(--text-secondary)] border border-[var(--border)]'
            }`}
          >
            <span>筛选</span>
            {hasActiveFilters && (
              <span className="w-4 h-4 rounded-full bg-white text-[var(--primary)] text-[10px] font-bold flex items-center justify-center">
                {filters.sources.length + (filters.timeRange !== 'all' ? 1 : 0)}
              </span>
            )}
          </button>

          {hasActiveFilters && (
            <button
              onClick={clearFilters}
              className="text-xs text-[var(--primary)] hover:underline"
            >
              清除筛选
            </button>
          )}
        </div>

        {/* 筛选面板 */}
        {showFilters && (
          <div className="mt-3 p-4 bg-[var(--background)] rounded-xl border border-[var(--border)]">
            {/* 来源筛选 */}
            <div className="mb-4">
              <h3 className="text-xs font-semibold text-[var(--text-muted)] mb-2 uppercase tracking-wide">
                来源
              </h3>
              <div className="flex flex-wrap gap-2">
                {SOURCES.map(source => (
                  <button
                    key={source.value}
                    onClick={() => toggleSource(source.value)}
                    className={`px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${
                      filters.sources.includes(source.value)
                        ? 'bg-[var(--primary)] text-white'
                        : 'bg-white text-[var(--text-secondary)] border border-[var(--border)] hover:border-[var(--primary)]'
                    }`}
                  >
                    {source.label}
                  </button>
                ))}
              </div>
            </div>

            {/* 时间范围筛选 */}
            <div>
              <h3 className="text-xs font-semibold text-[var(--text-muted)] mb-2 uppercase tracking-wide">
                时间范围
              </h3>
              <div className="flex flex-wrap gap-2">
                {TIME_RANGES.map(range => (
                  <button
                    key={range.value}
                    onClick={() => setTimeRange(range.value)}
                    className={`px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${
                      filters.timeRange === range.value
                        ? 'bg-[var(--primary)] text-white'
                        : 'bg-white text-[var(--text-secondary)] border border-[var(--border)] hover:border-[var(--primary)]'
                    }`}
                  >
                    {range.label}
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* 结果 */}
      <div className="p-4 md:p-5">
        {loading ? (
          <div className="flex items-center justify-center py-12">
            <div className="w-8 h-8 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin"></div>
          </div>
        ) : query || hasActiveFilters ? (
          <>
            <div className="text-sm text-[var(--text-muted)] mb-4">
              {query ? (
                <>
                  找到 <span className="font-semibold text-[var(--foreground)]">{results.length}</span> 个结果
                  {tookMs > 0 && <span className="ml-2">耗时 {tookMs}ms</span>}
                </>
              ) : hasActiveFilters ? (
                <>筛选条件：{filters.sources.length > 0 && `来源 ${filters.sources.join(', ')}`}{filters.timeRange !== 'all' && ` · ${TIME_RANGES.find(r => r.value === filters.timeRange)?.label}`}</>
              ) : null}
            </div>

            {results.length > 0 ? (
              <div className="space-y-3">
                {results.map((result, idx) => (
                  <a
                    key={`${result.type}-${result.id}-${idx}`}
                    href={getTypePath(result.type, result.id)}
                    className="block p-4 bg-white border border-[var(--border)] rounded-xl hover:border-[var(--primary)] hover:shadow-sm transition-all"
                  >
                    <div className="flex items-start gap-3">
                      <span className="text-2xl shrink-0">{getTypeIcon(result.type)}</span>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1 flex-wrap">
                          <span className="text-xs px-2 py-0.5 bg-[var(--background)] text-[var(--text-muted)] rounded">
                            {getTypeLabel(result.type)}
                          </span>
                          {result.source && (
                            <span className="text-xs px-2 py-0.5 bg-[var(--background)] text-[var(--text-muted)] rounded">
                              {result.source}
                            </span>
                          )}
                        </div>
                        <h3 className="font-semibold text-[var(--foreground)] mb-1">{result.title}</h3>
                        <p className="text-sm text-[var(--text-secondary)] line-clamp-2">{result.summary}</p>
                      </div>
                    </div>
                  </a>
                ))}
              </div>
            ) : (
              <EmptyState
                title="未找到相关结果"
                description="试试其他关键词，或调整筛选条件"
                icon="search"
              />
            )}
          </>
        ) : (
          <EmptyState
            title="搜索 AI 模型、资讯、评测"
            description="输入关键词开始搜索"
            icon="search"
          />
        )}
      </div>
    </div>
  );
}

export default function SearchPage() {
  return (
    <Suspense fallback={
      <div className="p-8 flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin"></div>
      </div>
    }>
      <SearchContent />
    </Suspense>
  );
}
