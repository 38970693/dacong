'use client';

import { useState, useEffect, useCallback } from 'react';

interface Tag {
  id: string;
  name: string;
  slug: string;
  color: string;
  post_count: number;
  created_at: string;
}

interface TagSelectorProps {
  selectedTags: Tag[];
  onSelect: (tag: Tag) => void;
  onClose: () => void;
}

export function TagSelector({ selectedTags, onSelect, onClose }: TagSelectorProps) {
  const [tags, setTags] = useState<Tag[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [creatingTag, setCreatingTag] = useState(false);
  const [newTagName, setNewTagName] = useState('');

  const fetchTags = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/tags');
      const json = await res.json();
      if (json.success) {
        setTags(json.data);
      }
    } catch {
      console.error('Fetch tags error');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTags();
  }, [fetchTags]);

  const handleCreateTag = useCallback(async () => {
    if (!newTagName.trim()) return;

    setCreatingTag(true);
    try {
      const res = await fetch('/api/tags', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: newTagName.trim() })
      });
      const json = await res.json();

      if (json.success) {
        setTags(prev => [json.data, ...prev]);
        onSelect(json.data);
      } else {
        alert(json.error || '创建标签失败');
      }
    } catch {
      alert('创建标签失败');
    } finally {
      setCreatingTag(false);
      setNewTagName('');
    }
  }, [newTagName, onSelect]);

  const filteredTags = tags.filter(tag =>
    tag.name.toLowerCase().includes(search.toLowerCase())
  );

  const availableTags = filteredTags.filter(
    tag => !selectedTags.some(st => st.id === tag.id)
  );

  const handleBackdropClick = useCallback((e: React.MouseEvent) => {
    if (e.target === e.currentTarget) {
      onClose();
    }
  }, [onClose]);

  return (
    <div
      className="fixed inset-0 z-50 bg-black/50 flex items-end sm:items-center justify-center"
      onClick={handleBackdropClick}
    >
      <div className="bg-white w-full sm:max-w-md sm:rounded-2xl max-h-[80vh] overflow-hidden flex flex-col animate-slide-up">
        {/* 头部 */}
        <div className="px-5 py-4 border-b border-[var(--border)] flex items-center justify-between">
          <h2 className="text-lg font-bold text-[var(--foreground)]">添加标签</h2>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-full hover:bg-[var(--background)] flex items-center justify-center transition-colors"
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* 搜索框 */}
        <div className="p-4 border-b border-[var(--border)]">
          <div className="relative">
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="搜索标签..."
              className="w-full pl-10 pr-4 py-2.5 bg-[var(--background)] rounded-xl text-sm text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
            />
            <svg
              className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-[var(--text-muted)]"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
            </svg>
          </div>
        </div>

        {/* 标签列表 */}
        <div className="flex-1 scroll-container p-4">
          {loading ? (
            <div className="flex justify-center py-8">
              <div className="w-6 h-6 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin"></div>
            </div>
          ) : (
            <>
              {/* 创建新标签 */}
              {search && !tags.some(t => t.name.toLowerCase() === search.toLowerCase()) && (
                <button
                  onClick={handleCreateTag}
                  disabled={creatingTag}
                  className="w-full p-3 mb-3 rounded-xl border border-dashed border-[var(--primary)] text-[var(--primary)] hover:bg-[var(--primary-light)] transition-colors flex items-center gap-2 text-sm disabled:opacity-50"
                >
                  {creatingTag ? (
                    <div className="w-4 h-4 border-2 border-current border-t-transparent rounded-full animate-spin"></div>
                  ) : (
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
                    </svg>
                  )}
                  创建 "{search}"
                </button>
              )}

              {/* 可选标签 */}
              {availableTags.length === 0 && !search ? (
                <div className="text-center py-8 text-[var(--text-muted)]">
                  <p>暂无可用标签</p>
                </div>
              ) : (
                <div className="flex flex-wrap gap-2">
                  {availableTags.map((tag) => (
                    <button
                      key={tag.id}
                      onClick={() => onSelect(tag)}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium transition-all hover:opacity-80"
                      style={{
                        backgroundColor: `${tag.color}15`,
                        color: tag.color
                      }}
                    >
                      #{tag.name}
                      <span className="opacity-60">{tag.post_count}</span>
                    </button>
                  ))}
                </div>
              )}
            </>
          )}
        </div>

        {/* 已选标签 */}
        {selectedTags.length > 0 && (
          <div className="p-4 border-t border-[var(--border)]">
            <p className="text-xs text-[var(--text-muted)] mb-2">已添加：</p>
            <div className="flex flex-wrap gap-2">
              {selectedTags.map((tag) => (
                <span
                  key={tag.id}
                  className="inline-flex items-center gap-1 px-3 py-1.5 rounded-full text-xs font-medium"
                  style={{
                    backgroundColor: `${tag.color}15`,
                    color: tag.color
                  }}
                >
                  #{tag.name}
                </span>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}