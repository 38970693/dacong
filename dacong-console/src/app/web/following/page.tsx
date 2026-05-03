'use client';

import { useUserStore } from '@/stores';

export default function FollowingPage() {
  const { isAuthenticated } = useUserStore();

  if (!isAuthenticated) {
    return (
      <div className="pb-16 md:pb-0">
        <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
          <h1 className="text-lg font-bold text-[var(--foreground)] flex items-center gap-2">
            <span>❤️</span>
            <span>关注</span>
          </h1>
        </div>
        <div className="p-6 md:p-8 text-center">
          <div className="w-20 h-20 mx-auto mb-4 rounded-2xl bg-[var(--primary-light)] flex items-center justify-center">
            <span className="text-4xl">🔐</span>
          </div>
          <p className="text-[var(--text-secondary)] mb-2">登录后查看关注内容</p>
          <p className="text-xs text-[var(--text-muted)]">关注你感兴趣的用户，第一时间获取他们的最新动态</p>
        </div>
      </div>
    );
  }

  return (
    <div className="pb-16 md:pb-0">
      <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        <h1 className="text-lg font-bold text-[var(--foreground)] flex items-center gap-2">
          <span>❤️</span>
          <span>关注</span>
        </h1>
        <p className="text-xs text-[var(--text-muted)] hidden md:block">你关注的用户发布的最新内容</p>
      </div>
      <div className="p-6 md:p-8 text-center">
        <div className="w-20 h-20 mx-auto mb-4 rounded-2xl bg-[var(--primary-light)] flex items-center justify-center">
          <span className="text-4xl">📭</span>
        </div>
        <p className="text-[var(--text-secondary)] mb-2">暂无关注动态</p>
        <p className="text-xs text-[var(--text-muted)]">去发现页探索你感兴趣的内容吧</p>
      </div>
    </div>
  );
}