import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // output: 'export', // 静态导出模式，不支持动态路由
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
