'use client';

interface EmptyStateProps {
  title: string;
  description?: string;
  icon?: 'news' | 'bookmark' | 'notification' | 'search' | 'comment';
  action?: {
    label: string;
    onClick: () => void;
  };
}

const ICONS: Record<NonNullable<EmptyStateProps['icon']>, string> = {
  news: 'M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z',
  bookmark: 'M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z',
  notification: 'M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9',
  search: 'M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z',
  comment: 'M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z'
};

const DEFAULT_DESCRIPTIONS: Record<NonNullable<EmptyStateProps['icon']>, string> = {
  news: '暂无新闻内容',
  bookmark: '还没有收藏任何内容',
  notification: '暂无通知',
  search: '没有找到相关结果',
  comment: '还没有评论'
};

export function EmptyState({ title, description, icon = 'news', action }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 px-4 text-center">
      {/* 图标 */}
      <div className="w-20 h-20 rounded-full bg-[var(--background)] flex items-center justify-center mb-6">
        <svg
          className="w-10 h-10 text-[var(--text-muted)]"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          strokeWidth={1.5}
        >
          <path strokeLinecap="round" strokeLinejoin="round" d={ICONS[icon]} />
        </svg>
      </div>

      {/* 标题 */}
      <h3 className="text-lg font-medium text-[var(--foreground)] mb-2">{title}</h3>

      {/* 描述 */}
      <p className="text-sm text-[var(--text-secondary)] mb-6 max-w-sm">
        {description || DEFAULT_DESCRIPTIONS[icon]}
      </p>

      {/* 操作按钮 */}
      {action && (
        <button
          onClick={action.onClick}
          className="px-6 py-2.5 bg-[var(--primary)] text-white rounded-full text-sm font-medium hover:bg-[var(--primary-dark)] transition-colors"
        >
          {action.label}
        </button>
      )}
    </div>
  );
}
