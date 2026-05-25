'use client';

import { useState, useEffect, useRef } from 'react';
import type { SearchResult } from '@/types/database';

interface SearchBarProps {
  className?: string;
  placeholder?: string;
  autoFocus?: boolean;
}

export default function SearchBar({ className = '', placeholder = '搜索 AI 模型、评测文章...', autoFocus }: SearchBarProps) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<SearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [isOpen, setIsOpen] = useState(false);
  const [tookMs, setTookMs] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  useEffect(() => {
    if (!query || query.length < 2) {
      setResults([]);
      return;
    }

    const timer = setTimeout(async () => {
      setLoading(true);
      try {
        const res = await fetch(`/api/search?q=${encodeURIComponent(query)}`);
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
    }, 300);

    return () => clearTimeout(timer);
  }, [query]);

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

  return (
    <div ref={containerRef} className={`relative ${className}`}>
      {/* 搜索输入框 */}
      <div className="relative">
        <input
          ref={inputRef}
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onFocus={() => setIsOpen(true)}
          placeholder={placeholder}
          autoFocus={autoFocus}
          className="w-full px-4 py-2.5 pl-10 bg-[var(--background)] border border-[var(--border)] rounded-full text-sm text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)] focus:ring-2 focus:ring-[var(--primary)]/20 transition-all"
        />
        <span className="absolute left-3 top-1/2 -translate-y-1/2 text-[var(--text-muted)]">
          {loading ? (
            <span className="w-4 h-4 border border-[var(--text-muted)] border-t-transparent rounded-full animate-spin inline-block"></span>
          ) : (
            '🔍'
          )}
        </span>
        {query && (
          <button
            onClick={() => { setQuery(''); setResults([]); inputRef.current?.focus(); }}
            className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 rounded-full bg-[var(--text-muted)] text-white flex items-center justify-center text-xs hover:bg-[var(--foreground)] transition-colors"
          >
            ✕
          </button>
        )}
      </div>

      {/* 搜索结果下拉 */}
      {isOpen && query.length >= 2 && (
        <div className="absolute top-full left-0 right-0 mt-2 bg-white rounded-2xl border border-[var(--border)] shadow-lg z-50 max-h-96 scroll-container">
          {results.length > 0 ? (
            <>
              {/* 搜索信息 */}
              <div className="px-4 py-2 bg-[var(--background)] text-xs text-[var(--text-muted)] border-b border-[var(--border)]">
                找到 {results.length} 个结果，耗时 {tookMs}ms
              </div>

              {/* 结果列表 */}
              {results.map((result, idx) => (
                <a
                  key={`${result.type}-${result.id}-${idx}`}
                  href={
                    result.type === 'post' ? `/web/post/${result.id}` :
                    result.type === 'review' ? `/web/review/${result.id}` :
                    `/web/ranking`
                  }
                  className="flex items-start gap-3 px-4 py-3 hover:bg-[var(--background)] transition-colors border-b border-[var(--border)] last:border-0"
                >
                  <span className="text-xl shrink-0">{getTypeIcon(result.type)}</span>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="text-xs px-1.5 py-0.5 bg-[var(--background)] text-[var(--text-muted)] rounded">
                        {getTypeLabel(result.type)}
                      </span>
                    </div>
                    <h4 className="text-sm font-medium text-[var(--foreground)] truncate">{result.title}</h4>
                    <p className="text-xs text-[var(--text-muted)] truncate mt-0.5">{result.summary}</p>
                  </div>
                </a>
              ))}
            </>
          ) : !loading && (
            <div className="p-8 text-center text-[var(--text-muted)]">
              <div className="text-2xl mb-2">🔍</div>
              <p>未找到相关结果</p>
              <p className="text-xs mt-1">试试其他关键词</p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}