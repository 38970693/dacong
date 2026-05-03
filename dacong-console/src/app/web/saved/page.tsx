'use client';

import { useUserStore } from '@/stores';

export default function SavedPage() {
  const { isAuthenticated } = useUserStore();

  if (!isAuthenticated) {
    return (
      <div className="pb-16 md:pb-0">
        <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
          <h1 className="text-lg font-bold text-[var(--foreground)] flex items-center gap-2">
            <span>📚</span>
            <span>收藏</span>
          </h1>
        </div>
        <div className="p-6 md:p-8 text-center">
          <div className="w-16 h-16 md:w-20 md:h-20 mx-auto mb-4 rounded-2xl bg-[var(--primary-light)] flex items-center justify-center">
            <span className="text-3xl md:text-4xl">🔐</span>
          </div>
          <p className="text-[var(--text-secondary)] mb-2">登录后查看收藏内容</p>
          <p className="text-xs text-[var(--text-muted)]">收藏你感兴趣的内容，随时随地查看</p>
        </div>
      </div>
    );
  }

  return (
    <div className="pb-16 md:pb-0">
      <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        <h1 className="text-lg font-bold text-[var(--foreground)] flex items-center gap-2">
          <span>📚</span>
          <span>收藏</span>
        </h1>
        <p className="text-xs text-[var(--text-muted)] hidden md:block">你收藏的所有内容</p>
      </div>
      <div className="p-6 md:p-8 text-center">
        <div className="w-16 h-16 md:w-20 md:h-20 mx-auto mb-4 rounded-2xl bg-[var(--primary-light)] flex items-center justify-center">
          <span className="text-3xl md:text-4xl">📝</span>
        </div>
        <p className="text-[var(--text-secondary)] mb-2">还没有收藏内容</p>
        <p className="text-xs text-[var(--text-muted)]">浏览时收藏感兴趣的内容，方便以后查看</p>
      </div>
    </div>
  );
}