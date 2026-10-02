import type { Metadata, Viewport } from "next";
import { AuthProvider } from "@/components/AuthProvider";
import { SkipLink, LiveRegion } from "@/components/a11y";
import "./globals.css";

export const metadata: Metadata = {
  title: "DaCong - AI 动态与每日摘要",
  description: "聚合模型发布、AI Agent、开发工具、开源项目与研究进展，保留原文出处，提供每日精选和中英文切换。",
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || 'https://dacong-weld.vercel.app'),
  openGraph: {
    type: "website",
    locale: "zh_CN",
    siteName: "DaCong",
  },
  icons: {
    icon: '/favicon.ico',
  },
  manifest: '/manifest.json',
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  viewportFit: "cover",
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#ffffff" },
    { media: "(prefers-color-scheme: dark)", color: "#1a1a1a" },
  ],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="zh-CN" suppressHydrationWarning>
      <body
        className="min-h-screen bg-[var(--background)]"
        /**
         * 支持减弱动效偏好 (WCAG 2.1 AA)
         * 用户在操作系统设置中启用"减弱动画效果"时，自动禁用 CSS 动画
         */
        style={{ scrollBehavior: 'smooth' }}
      >
        {/* 跳转到主内容链接 (WCAG 要求) */}
        <SkipLink />

        {/* 屏幕阅读器公告区域 */}
        <LiveRegion />

        <AuthProvider>
          {/* 主内容区域 */}
          <main id="main-content" tabIndex={-1}>
            {children}
          </main>
        </AuthProvider>

        {/* 减弱动效支持 */}
        <script
          dangerouslySetInnerHTML={{
            __html: `
              (function() {
                var prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
                if (prefersReducedMotion.matches) {
                  document.documentElement.classList.add('reduce-motion');
                }
                prefersReducedMotion.addEventListener('change', function(e) {
                  if (e.matches) {
                    document.documentElement.classList.add('reduce-motion');
                  } else {
                    document.documentElement.classList.remove('reduce-motion');
                  }
                });
              })();
            `,
          }}
        />
      </body>
    </html>
  );
}
