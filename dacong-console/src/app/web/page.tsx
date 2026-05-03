'use client';

import { usePostsStore } from '@/stores';
import { PostCard } from '@/components/PostCard';

export default function HomePage() {
  const { posts, isLoading, error, fetchPosts } = usePostsStore();

  // 模拟加载
  const mockPosts = posts.length > 0 ? posts : [
    {
      id: '1',
      title: 'Claude 3 发布：超越 GPT-4 的多模态 AI 助手',
      content: 'Anthropic 刚刚发布了 Claude 3 系列模型，在多项基准测试中超越了 GPT-4...',
      source: 'HackerNews',
      source_url: null,
      views: 1234,
      likes: 234,
      comments_count: 56,
      created_at: new Date().toISOString(),
    },
    {
      id: '2',
      title: 'GPT-5 即将发布？OpenAI 工程师透露新进展',
      content: '据内部人士透露，GPT-5 将在今年晚些时候发布，重点提升推理能力...',
      source: 'Reddit',
      source_url: null,
      views: 5678,
      likes: 1200,
      comments_count: 234,
      created_at: new Date(Date.now() - 900000).toISOString(),
    },
    {
      id: '3',
      title: 'Llama 3 开源发布，性能接近 GPT-4',
      content: 'Meta 发布的 Llama 3 模型在多项测试中表现出色，完全开源可商用...',
      source: 'Twitter',
      source_url: null,
      views: 3456,
      likes: 892,
      comments_count: 145,
      created_at: new Date(Date.now() - 1800000).toISOString(),
    },
    {
      id: '4',
      title: 'Google Gemini Pro 正式开放 API，免费额度大幅提升',
      content: 'Google 宣布 Gemini Pro API 正式开放，并提供大量免费额度...',
      source: '官方',
      source_url: null,
      views: 4567,
      likes: 1567,
      comments_count: 234,
      created_at: new Date(Date.now() - 3600000).toISOString(),
    },
  ];

  return (
    <div className="pb-16 md:pb-0">
      {/* 页面标题 */}
      <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        <h1 className="text-lg font-bold text-[var(--foreground)]">首页</h1>
        <p className="text-xs text-[var(--text-muted)] hidden md:block">发现最新最热的 AI 模型相关内容</p>
      </div>

      {/* 帖子列表 */}
      <div className="divide-y divide-[var(--border)]">
        {mockPosts.map((post, index) => (
          <div
            key={post.id}
            className="p-4 md:p-5 hover:bg-[var(--background)] transition-colors cursor-pointer"
            style={{ animationDelay: `${index * 50}ms` }}
          >
            <PostCard post={post} />
          </div>
        ))}
      </div>

      {/* 加载更多 */}
      <div className="p-6 md:p-8 text-center">
        <div className="inline-flex items-center gap-2 text-sm text-[var(--text-muted)]">
          <span className="w-8 h-px bg-[var(--border)]"></span>
          <span>没有更多了</span>
          <span className="w-8 h-px bg-[var(--border)]"></span>
        </div>
      </div>
    </div>
  );
}