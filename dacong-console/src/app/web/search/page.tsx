'use client';

import { useState, useEffect, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import SearchBar from '@/components/SearchBar';
import type { SearchResult } from '@/types/database';

function SearchContent() {
  const searchParams = useSearchParams();
  const initialQuery = searchParams.get('q') || '';
  const [results, setResults] = useState<SearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [query, setQuery] = useState(initialQuery);
  const [tookMs, setTookMs] = useState(0);

  useEffect(() => {
    if (initialQuery) {
      performSearch(initialQuery);
    }
  }, [initialQuery]);

  async function performSearch(q: string) {
    if (!q || q.length < 2) return;
    setLoading(true);
    setQuery(q);
    try {
      const res = await fetch(`/api/search?q=${encodeURIComponent(q)}`);
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
  }

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

  return (
    <div className="pb-16 md:pb-0">
      {/* 页面标题 */}
      <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        <h1 className="text-lg font-bold text-[var(--foreground)] flex items-center gap-2 mb-3">
          <span>🔍</span>
          <span>搜索</span>
        </h1>
        <SearchBar autoFocus={!initialQuery} />
      </div>

      {/* 结果 */}
      <div className="p-4 md:p-5">
        {loading ? (
          <div className="flex items-center justify-center py-12">
            <div className="w-8 h-8 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin"></div>
          </div>
        ) : query ? (
          <>
            <div className="text-sm text-[var(--text-muted)] mb-4">
              找到 <span className="font-semibold text-[var(--foreground)]">{results.length}</span> 个结果
              {tookMs > 0 && <span className="ml-2">耗时 {tookMs}ms</span>}
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
                        <div className="flex items-center gap-2 mb-1">
                          <span className="text-xs px-2 py-0.5 bg-[var(--background)] text-[var(--text-muted)] rounded">
                            {getTypeLabel(result.type)}
                          </span>
                        </div>
                        <h3 className="font-semibold text-[var(--foreground)] mb-1">{result.title}</h3>
                        <p className="text-sm text-[var(--text-secondary)] line-clamp-2">{result.summary}</p>
                      </div>
                    </div>
                  </a>
                ))}
              </div>
            ) : (
              <div className="text-center py-12">
                <div className="text-4xl mb-4">🔍</div>
                <h3 className="font-semibold text-[var(--foreground)] mb-2">未找到相关结果</h3>
                <p className="text-sm text-[var(--text-muted)]">试试其他关键词</p>
              </div>
            )}
          </>
        ) : (
          <div className="text-center py-12">
            <div className="text-4xl mb-4">💡</div>
            <h3 className="font-semibold text-[var(--foreground)] mb-2">搜索 AI 模型、评测文章</h3>
            <p className="text-sm text-[var(--text-muted)]">输入关键词开始搜索</p>
          </div>
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