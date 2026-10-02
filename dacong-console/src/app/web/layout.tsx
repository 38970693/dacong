'use client';

import { WebHeader } from '@/components/web/WebHeader';
import { WebSidebar } from '@/components/web/WebSidebar';
import { RightSidebar } from '@/components/web/RightSidebar';
import { ToastProvider } from '@/components/ui/Toast';

export default function WebLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <ToastProvider>
      <div className="min-h-screen bg-[var(--background)]">
        <WebHeader />
        <div className="pt-14 md:pt-16 flex justify-center">
          <div className="flex w-full max-w-7xl">
            {/* 桌面端左侧边栏 - lg 及以上显示 */}
            <WebSidebar />

            {/* 主内容区 */}
            <main className="min-w-0 w-full flex-1 max-w-2xl border-x border-[var(--border)] min-h-[calc(100dvh-56px)] md:min-h-[calc(100dvh-64px)] pb-16 lg:pb-0">
              {children}
            </main>

            {/* 右侧边栏 - xl 及以上显示 */}
            <RightSidebar />
          </div>
        </div>
      </div>
    </ToastProvider>
  );
}
