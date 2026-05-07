'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import type { Tag } from '@/types/database';

interface TagCloudProps {
  maxTags?: number;
  minPostCount?: number;
}

export function TagCloud({ maxTags = 50, minPostCount = 0 }: TagCloudProps) {
  const [tags, setTags] = useState<Tag[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchTags();
  }, []);

  async function fetchTags() {
    try {
      const res = await fetch('/api/tags');
      const json = await res.json();
      if (json.success && json.data?.length > 0) {
        const filtered = json.data
          .filter((tag: Tag) => tag.post_count >= minPostCount)
          .slice(0, maxTags);
        setTags(filtered);
      } else {
        setTags(getMockTags());
      }
    } catch {
      setTags(getMockTags());
    } finally {
      setLoading(false);
    }
  }

  function getMockTags(): Tag[] {
    return [
      { id: '1', name: 'AI', slug: 'ai', color: '#3B82F6', post_count: 156, created_at: '' },
      { id: '2', name: '编程', slug: 'programming', color: '#10B981', post_count: 89, created_at: '' },
      { id: '3', name: '创意写作', slug: 'creative-writing', color: '#EC4899', post_count: 67, created_at: '' },
      { id: '4', name: '数学推理', slug: 'math', color: '#F59E0B', post_count: 123, created_at: '' },
      { id: '5', name: '多模态', slug: 'multimodal', color: '#8B5CF6', post_count: 45, created_at: '' },
      { id: '6', name: 'RAG', slug: 'rag', color: '#6366F1', post_count: 234, created_at: '' },
      { id: '7', name: '开源', slug: 'open-source', color: '#22C55E', post_count: 178, created_at: '' },
      { id: '8', name: '中文', slug: 'chinese', color: '#EF4444', post_count: 56, created_at: '' },
      { id: '9', name: '对比评测', slug: 'benchmark', color: '#F97316', post_count: 98, created_at: '' },
      { id: '10', name: '大模型', slug: 'llm', color: '#14B8A6', post_count: 167, created_at: '' },
    ];
  }

  // 计算字体大小（基于 post_count）
  function getFontSize(postCount: number, maxCount: number): number {
    const minSize = 12;
    const maxSize = 24;
    if (maxCount === 0) return minSize;
    const ratio = postCount / maxCount;
    return minSize + (maxSize - minSize) * ratio;
  }

  if (loading) {
    return (
      <div className="flex flex-wrap gap-3 items-center justify-center p-4">
        {[1, 2, 3, 4, 5, 6].map((i) => (
          <div key={i} className="w-16 h-6 bg-[var(--background)] rounded animate-pulse"></div>
        ))}
      </div>
    );
  }

  if (tags.length === 0) {
    return (
      <div className="text-center py-8 text-[var(--text-muted)]">
        <p>暂无标签</p>
      </div>
    );
  }

  const maxCount = Math.max(...tags.map(t => t.post_count));

  return (
    <div className="flex flex-wrap gap-3 items-center justify-center">
      {tags.map((tag) => (
        <Link
          key={tag.id}
          href={`/tags/${tag.slug}`}
          className="transition-transform hover:scale-110"
          style={{ color: tag.color }}
        >
          <span
            className="font-medium"
            style={{ fontSize: `${getFontSize(tag.post_count, maxCount)}px` }}
          >
            #{tag.name}
          </span>
          <span className="ml-1 opacity-50" style={{ fontSize: '12px' }}>
            {tag.post_count}
          </span>
        </Link>
      ))}
    </div>
  );
}