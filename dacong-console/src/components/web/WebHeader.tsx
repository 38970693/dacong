'use client';

/**
 * WebHeader - 网站头部导航 (WCAG 2.1 AA 无障碍支持)
 */
import Link from 'next/link';
import { useEffect, useState, useId } from 'react';
import { useAuthStore } from '@/stores';
import { ThemeSwitcher } from '@/components/theme/ThemeSwitcher';
import { NotificationBell } from '@/components/NotificationBell';

export function WebHeader() {
  const { user, initialize, isAuthenticated } = useAuthStore();
  const [isInitialized, setIsInitialized] = useState(false);
  const searchId = useId();

  useEffect(() => {
    initialize().then(() => setIsInitialized(true));
  }, [initialize]);

  return (
    <>
      {/* 桌面端顶部导航 */}
      <header
        className="fixed top-0 left-0 right-0 h-16 bg-white border-b border-[var(--border)] z-50 hidden md:flex items-center justify-between px-6"
        role="banner"
      >
        {/* Logo */}
        <Link
          href="/web"
          className="text-xl font-bold text-[var(--foreground)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] rounded px-2 -ml-2"
          aria-label="DaCong 首页"
        >
          Da<span className="text-[var(--primary)]">Cong</span>
        </Link>

        {/* 搜索框 - 桌面端 */}
        <div className="flex-1 max-w-md mx-8 relative hidden lg:block">
          <label htmlFor={searchId} className="sr-only">搜索 AI 模型、话题</label>
          <svg
            className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[var(--text-muted)]"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
            aria-hidden="true"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z"
            />
          </svg>
          <input
            id={searchId}
            type="search"
            placeholder="搜索 AI 模型、话题..."
            className="w-full pl-11 pr-4 py-2.5 bg-[var(--background)] border border-[var(--border)] rounded-full text-sm outline-none transition-all focus:border-[var(--primary)] focus:bg-white focus:shadow-[0_0_0_3px_rgba(245,158,11,0.1)]"
            aria-label="搜索 AI 模型、话题"
          />
        </div>

        {/* 操作按钮 - 桌面端 */}
        <nav className="flex items-center gap-3" role="navigation" aria-label="主要导航">
          {/* 通知 */}
          <NotificationBell />

          {/* 主题切换 */}
          <ThemeSwitcher />

          <button
            className="w-10 h-10 rounded-full bg-[var(--background)] flex items-center justify-center text-[var(--text-secondary)] hover:bg-[var(--primary-light)] hover:text-[var(--primary)] transition-all"
            aria-label="消息"
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2} aria-hidden="true">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
              />
            </svg>
          </button>

          {isInitialized && isAuthenticated && user ? (
            <Link
              href="/web/profile"
              className="flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium hover:bg-[var(--background)] transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)]"
              aria-label={`用户 ${user.email} 的个人资料`}
            >
              <div className="w-8 h-8 rounded-full bg-[var(--primary)] text-white flex items-center justify-center text-sm font-bold" aria-hidden="true">
                {user.email?.charAt(0).toUpperCase() || 'U'}
              </div>
              <span className="hidden lg:inline">{user.email?.split('@')[0]}</span>
            </Link>
          ) : (
            <Link
              href="/web/auth/login"
              className="flex items-center gap-2 px-5 py-2.5 bg-[var(--primary)] text-white rounded-full text-sm font-semibold hover:bg-[var(--primary-dark)] transition-all hover:shadow-lg hover:shadow-[var(--primary)]/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[var(--primary)]"
            >
              登录
            </Link>
          )}
        </nav>
      </header>

      {/* 移动端顶部导航 - 简化版 */}
      <header
        className="fixed top-0 left-0 right-0 h-14 bg-white border-b border-[var(--border)] z-50 flex md:hidden items-center justify-between px-4"
        role="banner"
      >
        <Link
          href="/web"
          className="text-lg font-bold text-[var(--foreground)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)] rounded px-2 -ml-2"
          aria-label="DaCong 首页"
        >
          Da<span className="text-[var(--primary)]">Cong</span>
        </Link>

        <nav className="flex items-center gap-2" role="navigation" aria-label="移动导航">
          {isInitialized && isAuthenticated && user ? (
            <Link
              href="/web/profile"
              className="w-8 h-8 rounded-full bg-[var(--primary)] text-white flex items-center justify-center text-xs font-bold focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)]"
              aria-label={`用户 ${user.email} 的个人资料`}
            >
              {user.email?.charAt(0).toUpperCase() || 'U'}
            </Link>
          ) : (
            <Link
              href="/web/auth/login"
              className="px-4 py-1.5 bg-[var(--primary)] text-white rounded-full text-xs font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--primary)]"
            >
              登录
            </Link>
          )}

          {/* 移动端搜索按钮 */}
          <button
            className="w-10 h-10 rounded-full bg-[var(--background)] flex items-center justify-center text-[var(--text-secondary)]"
            aria-label="搜索"
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2} aria-hidden="true">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z"
              />
            </svg>
          </button>
        </nav>
      </header>
    </>
  );
}