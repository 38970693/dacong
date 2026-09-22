'use client';

/**
 * AdminLayout - 管理后台布局
 */
import Link from 'next/link';
import { usePathname } from 'next/navigation';

const adminNav = [
  {
    label: 'AI 动态',
    href: '/admin/dynamics',
    icon: (
      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 12h16M4 18h10" />
      </svg>
    ),
  },
  {
    label: '文章管理',
    href: '/admin/reviews',
    icon: (
      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z" />
      </svg>
    ),
  },
  {
    label: '内容审核',
    href: '/web/admin/audit-logs',
    icon: (
      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
        <path strokeLinecap="round" strokeLinejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
    ),
  },
];

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();

  return (
    <div className="min-h-screen bg-[var(--background)]">
      {/* 管理后台导航 */}
      <aside className="fixed left-0 top-0 bottom-0 w-64 bg-white border-r border-[var(--border)] p-4 hidden md:block">
        {/* Logo */}
        <div className="mb-6 px-2">
          <Link
            href="/"
            className="text-xl font-bold text-[var(--foreground)]"
          >
            Da<span className="text-[var(--primary)]">Cong</span>
            <span className="text-sm font-normal text-[var(--text-muted)] ml-2">管理后台</span>
          </Link>
        </div>

        {/* 导航 */}
        <nav className="space-y-1">
          {adminNav.map((item) => {
            const isActive = pathname.startsWith(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-[var(--primary)] text-white'
                    : 'text-[var(--text-secondary)] hover:bg-[var(--background)] hover:text-[var(--foreground)]'
                }`}
              >
                {item.icon}
                <span>{item.label}</span>
              </Link>
            );
          })}
        </nav>

        {/* 底部链接 */}
        <div className="absolute bottom-4 left-4 right-4">
          <Link
            href="/"
            className="flex items-center gap-2 px-3 py-2 text-sm text-[var(--text-muted)] hover:text-[var(--foreground)] transition-colors"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M11 17l-5-5m0 0l5-5m-5 5h12" />
            </svg>
            返回前台
          </Link>
        </div>
      </aside>

      {/* 移动端顶部导航 */}
      <div className="md:hidden fixed top-0 left-0 right-0 h-14 bg-white border-b border-[var(--border)] flex items-center justify-between px-4 z-50">
        <Link href="/" className="text-lg font-bold text-[var(--foreground)]">
          Da<span className="text-[var(--primary)]">Cong</span>
          <span className="text-xs font-normal text-[var(--text-muted)] ml-1">管理</span>
        </Link>
        <Link
          href="/"
          className="px-3 py-1.5 text-xs text-[var(--text-muted)] hover:text-[var(--foreground)]"
        >
          返回前台
        </Link>
      </div>

      {/* 主内容区 */}
      <main className="md:ml-64 p-4 md:p-6 pt-16 md:pt-6">
        {children}
      </main>
    </div>
  );
}
