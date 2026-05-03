'use client';

import { WebHeader } from '@/components/web/WebHeader';
import { WebSidebar } from '@/components/web/WebSidebar';
import { RightSidebar } from '@/components/web/RightSidebar';

export default function WebLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-[var(--background)]">
      <WebHeader />
      <div className="pt-16 md:pt-16 flex justify-center">
        <div className="flex w-full max-w-7xl">
          {/* 桌面端左侧边栏 - lg 及以上显示 */}
          <WebSidebar />

          {/* 主内容区 */}
          <main className="flex-1 max-w-2xl border-x border-[var(--border)] min-h-[calc(100vh-64px)] pb-16 md:pb-0">
            {children}
          </main>

          {/* 右侧边栏 - xl 及以上显示 */}
          <RightSidebar />
        </div>
      </div>
    </div>
  );
}