'use client';

import Link from 'next/link';

export function WebHeader() {
  return (
    <>
      {/* 桌面端顶部导航 */}
      <header className="fixed top-0 left-0 right-0 h-16 bg-white border-b border-[var(--border)] z-50 hidden md:flex items-center justify-between px-6">
        {/* Logo */}
        <Link href="/web" className="text-xl font-bold text-[var(--foreground)]">
          Da<span className="text-[var(--primary)]">Cong</span>
        </Link>

        {/* 搜索框 - 桌面端 */}
        <div className="flex-1 max-w-md mx-8 relative hidden lg:block">
          <svg
            className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[var(--text-muted)]"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z"
            />
          </svg>
          <input
            type="text"
            placeholder="搜索 AI 模型、话题..."
            className="w-full pl-11 pr-4 py-2.5 bg-[var(--background)] border border-[var(--border)] rounded-full text-sm outline-none transition-all focus:border-[var(--primary)] focus:bg-white focus:shadow-[0_0_0_3px_rgba(245,158,11,0.1)]"
          />
        </div>

        {/* 操作按钮 - 桌面端 */}
        <div className="flex items-center gap-3">
          <button
            className="w-10 h-10 rounded-full bg-[var(--background)] flex items-center justify-center text-[var(--text-secondary)] hover:bg-[var(--primary-light)] hover:text-[var(--primary)] transition-all"
            title="通知"
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"
              />
            </svg>
          </button>

          <button
            className="w-10 h-10 rounded-full bg-[var(--background)] flex items-center justify-center text-[var(--text-secondary)] hover:bg-[var(--primary-light)] hover:text-[var(--primary)] transition-all"
            title="消息"
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
              />
            </svg>
          </button>

          <button className="flex items-center gap-2 px-5 py-2.5 bg-[var(--primary)] text-white rounded-full text-sm font-semibold hover:bg-[var(--primary-dark)] transition-all hover:shadow-lg hover:shadow-[var(--primary)]/30">
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 4v16m8-8H4" />
            </svg>
            <span className="hidden lg:inline">发布</span>
          </button>
        </div>
      </header>

      {/* 移动端顶部导航 - 简化版 */}
      <header className="fixed top-0 left-0 right-0 h-14 bg-white border-b border-[var(--border)] z-50 flex md:hidden items-center justify-between px-4">
        <Link href="/web" className="text-lg font-bold text-[var(--foreground)]">
          Da<span className="text-[var(--primary)]">Cong</span>
        </Link>

        {/* 移动端搜索按钮 */}
        <button className="w-10 h-10 rounded-full bg-[var(--background)] flex items-center justify-center text-[var(--text-secondary)]">
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z"
            />
          </svg>
        </button>
      </header>
    </>
  );
}