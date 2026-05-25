import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'export',
  images: {
    // 静态导出模式下禁用内置优化，使用 Image 组件的 unoptimized 属性
    unoptimized: true,
    // 允许加载外部图片（Google Favicons 等）
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'www.google.com',
        pathname: '/s2/favicons/**',
      },
      {
        protocol: 'https',
        hostname: '*.google.com',
      },
      {
        protocol: 'https',
        hostname: 'avatars.githubusercontent.com',
      },
      {
        protocol: 'https',
        hostname: 'lh3.googleusercontent.com',
      },
    ],
    // 默认格式
    formats: ['image/webp', 'image/avif'],
  },
};

export default nextConfig;
