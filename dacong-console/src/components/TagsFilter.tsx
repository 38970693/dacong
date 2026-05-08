'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import type { Tag } from '@/types/database';

interface TagsFilterProps {
  onTagSelect?: (tag: string | null) => void;
  selectedTag?: string | null;
  showAll?: boolean;
}

function getMockTags(): Tag[] {
  return [
    { id: '1', name: '编程', slug: 'programming', color: '#3B82F6', post_count: 156, created_at: '' },
    { id: '2', name: '创意写作', slug: 'creative-writing', color: '#EC4899', post_count: 89, created_at: '' },
    { id: '3', name: '数学推理', slug: 'math', color: '#F59E0B', post_count: 67, created_at: '' },
    { id: '4', name: '多模态', slug: 'multimodal', color: '#10B981', post_count: 123, created_at: '' },
    { id: '5', name: 'RAG', slug: 'rag', color: '#6366F1', post_count: 45, created_at: '' },
    { id: '6', name: '开源', slug: 'open-source', color: '#22C55E', post_count: 234, created_at: '' },
    { id: '7', name: '中文', slug: 'chinese', color: '#EF4444', post_count: 178, created_at: '' },
    { id: '8', name: '对比评测', slug: 'benchmark', color: '#F97316', post_count: 56, created_at: '' },
  ];
}

export function TagsFilter({ onTagSelect, selectedTag, showAll = true }: TagsFilterProps) {
  const [tags, setTags] = useState<Tag[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchTags = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/tags');
      const json = await res.json();
      if (json.success && json.data?.length > 0) {
        setTags(json.data);
      } else {
        setTags(getMockTags());
      }
    } catch {
      setTags(getMockTags());
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTags();
  }, [fetchTags]);

  if (loading) {
    return (
      <div className="flex flex-wrap gap-2">
        {[1, 2, 3, 4, 5].map((i) => (
          <div key={i} className="w-16 h-6 bg-[var(--background)] rounded-full animate-pulse"></div>
        ))}
      </div>
    );
  }

  return (
    <div className="flex flex-wrap gap-2">
      {showAll && (
        <button
          onClick={() => onTagSelect?.(null)}
          className={`px-3 py-1.5 rounded-full text-xs font-medium transition-all ${
            !selectedTag
              ? 'bg-[var(--foreground)] text-white'
              : 'bg-[var(--background)] text-[var(--text-muted)] hover:text-[var(--foreground)]'
          }`}
        >
          全部
        </button>
      )}
      {tags.map((tag) => (
        <Link
          key={tag.id}
          href={`/tags/${tag.slug}`}
          className={`px-3 py-1.5 rounded-full text-xs font-medium transition-all hover:opacity-80 ${
            selectedTag === tag.slug
              ? 'text-white'
              : 'text-[var(--text-muted)]'
          }`}
          style={{
            backgroundColor: selectedTag === tag.slug ? tag.color : 'var(--background)',
            color: selectedTag === tag.slug ? 'white' : 'var(--text-muted)',
          }}
        >
          #{tag.name}
          <span className="ml-1 opacity-60">{tag.post_count}</span>
        </Link>
      ))}
    </div>
  );
}