import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
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
