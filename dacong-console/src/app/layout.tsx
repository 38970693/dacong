import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import { Noto_Sans_SC } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800", "900"],
});

const notoSansSC = Noto_Sans_SC({
  variable: "--font-noto-sans-sc",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800", "900"],
});

export const metadata: Metadata = {
  title: "DaCong - AI 模型排行榜",
  description: "DaCong 汇聚全球顶尖 AI 模型，提供实时排行、社区讨论和最新资讯，让你在 AI 时代保持领先。",
  icons: {
    icon: '/favicon.ico',
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  viewportFit: "cover",
  themeColor: "#ffffff",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="zh-CN">
      <body className={`${inter.variable} ${notoSansSC.variable} h-dvh overflow-hidden bg-[var(--background)]`}>
        {children}
      </body>
    </html>
  );
}