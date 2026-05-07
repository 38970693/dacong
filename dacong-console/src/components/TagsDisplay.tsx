'use client';

import Link from 'next/link';

interface Tag {
  id: string;
  name: string;
  slug: string;
  color: string;
}

interface TagsDisplayProps {
  tags: Tag[];
  onRemove?: (tagId: string) => void;
  onAddClick?: () => void;
  showAddButton?: boolean;
}

export function TagsDisplay({
  tags,
  onRemove,
  onAddClick,
  showAddButton = true
}: TagsDisplayProps) {
  return (
    <div className="flex flex-wrap gap-2">
      {tags.map((tag) => (
        <div
          key={tag.id}
          className="group relative inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium transition-all hover:opacity-80"
          style={{
            backgroundColor: `${tag.color}15`,
            color: tag.color
          }}
        >
          <Link
            href={`/tags/${tag.slug}`}
            className="hover:underline"
            onClick={(e) => e.stopPropagation()}
          >
            #{tag.name}
          </Link>
          {onRemove && (
            <button
              onClick={(e) => {
                e.preventDefault();
                e.stopPropagation();
                onRemove(tag.id);
              }}
              className="w-4 h-4 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 hover:bg-black/10 transition-opacity"
              aria-label={`移除标签 ${tag.name}`}
            >
              <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          )}
        </div>
      ))}

      {showAddButton && (
        <button
          onClick={(e) => {
            e.preventDefault();
            e.stopPropagation();
            onAddClick?.();
          }}
          className="inline-flex items-center gap-1 px-3 py-1.5 rounded-full text-xs font-medium border border-dashed border-[var(--border)] text-[var(--text-muted)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors"
        >
          <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
          添加标签
        </button>
      )}
    </div>
  );
}