'use client';

import { useState } from 'react';
import { PostCard } from '@/components/PostCard';

const mockHotPosts = [
  {
    id: 'h1',
    title: 'Google Gemini Pro 正式开放 API，免费额度大幅提升',
    content: 'Google 宣布 Gemini Pro API 正式开放，并提供大量免费额度，开发者可以直接调用...',
    source: '官方公告',
    source_url: null,
    views: 12345,
    likes: 2345,
    comments_count: 567,
    created_at: new Date().toISOString(),
  },
  {
    id: 'h2',
    title: 'AI 编程助手大火，多款产品估值飙升',
    content: 'GitHub Copilot、Cursor 等 AI 编程工具掀起新一轮投资热潮，估值翻倍...',
    source: '科技资讯',
    source_url: null,
    views: 8765,
    likes: 1234,
    comments_count: 345,
    created_at: new Date(Date.now() - 7200000).toISOString(),
  },
  {
    id: 'h3',
    title: '2026 年 AI 模型排行榜发布，GPT-4 仍居榜首',
    content: '最新排名显示 Claude 3 与 GPT-4 并驾齐驱，差距逐渐缩小...',
    source: '数据分析',
    source_url: null,
    views: 6543,
    likes: 987,
    comments_count: 234,
    created_at: new Date(Date.now() - 14400000).toISOString(),
  },
];

const mockNewPosts = [
  {
    id: 'n1',
    title: 'OpenAI 推出新功能：GPT-4 支持图片理解',
    content: 'OpenAI 宣布 GPT-4 现在支持图片理解功能，用户可以上传图片进行问答...',
    source: '官方',
    source_url: null,
    views: 1234,
    likes: 456,
    comments_count: 89,
    created_at: new Date(Date.now() - 300000).toISOString(),
  },
  {
    id: 'n2',
    title: 'Anthropic 融资 30 亿美元，估值超 200 亿',
    content: 'AI 初创公司 Anthropic 完成新一轮融资，估值突破 200 亿美元...',
    source: '财经',
    source_url: null,
    views: 3456,
    likes: 678,
    comments_count: 123,
    created_at: new Date(Date.now() - 600000).toISOString(),
  },
];

export default function TrendingPage() {
  const [activeTab, setActiveTab] = useState<'hot' | 'new'>('hot');
  const currentPosts = activeTab === 'hot' ? mockHotPosts : mockNewPosts;

  return (
    <div className="pb-16 md:pb-0">
      {/* 页面标题 */}
      <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        <h1 className="text-lg font-bold text-[var(--foreground)] flex items-center gap-2">
          <span>🔥</span>
          <span>热门榜单</span>
        </h1>
        <p className="text-xs text-[var(--text-muted)] hidden md:block">实时更新 · 每30秒刷新</p>
      </div>

      {/* 标签切换 */}
      <div className="flex gap-2 md:gap-3 px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        <button
          onClick={() => setActiveTab('hot')}
          className={`px-5 py-2 rounded-full text-sm font-semibold transition-all ${
            activeTab === 'hot'
              ? 'bg-[var(--primary)] text-white shadow-lg shadow-[var(--primary)]/30'
              : 'bg-white text-[var(--text-secondary)] border border-[var(--border)] hover:border-[var(--primary)] hover:text-[var(--primary)]'
          }`}
        >
          🌡️ 热榜
        </button>
        <button
          onClick={() => setActiveTab('new')}
          className={`px-5 py-2 rounded-full text-sm font-semibold transition-all ${
            activeTab === 'new'
              ? 'bg-[var(--primary)] text-white shadow-lg shadow-[var(--primary)]/30'
              : 'bg-white text-[var(--text-secondary)] border border-[var(--border)] hover:border-[var(--primary)] hover:text-[var(--primary)]'
          }`}
        >
          ✨ 最新
        </button>
      </div>

      {/* TOP 3 展示 */}
      {activeTab === 'hot' && (
        <div className="p-5 border-b border-[var(--border)]">
          <div className="bg-white rounded-2xl p-4 border border-[var(--border)] shadow-sm">
            <h3 className="text-sm font-semibold text-[var(--text-secondary)] mb-3 flex items-center gap-2">
              <span>🏆</span>
              <span>TOP 3</span>
            </h3>
            <div className="space-y-3">
              {mockHotPosts.slice(0, 3).map((post, idx) => (
                <div
                  key={post.id}
                  className={`flex items-center gap-4 p-3 rounded-xl transition-all ${
                    idx === 0 ? 'bg-[var(--primary-light)]' : 'bg-[var(--background)]'
                  }`}
                >
                  <span
                    className={`text-3xl font-bold w-10 text-center ${
                      idx === 0
                        ? 'text-[var(--primary)]'
                        : idx === 1
                        ? 'text-[var(--text-muted)]'
                        : 'text-[var(--primary-dark)]'
                    }`}
                  >
                    {idx + 1}
                  </span>
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold text-[var(--foreground)] truncate">{post.title}</p>
                    <p className="text-xs text-[var(--text-muted)] mt-1">
                      {post.source} • ❤️ {post.likes}
                    </p>
                  </div>
                  {idx === 0 && (
                    <span className="px-2 py-1 bg-[var(--primary)] text-white text-xs rounded-full font-medium">
                      热
                    </span>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* 帖子列表 */}
      <div className="divide-y divide-[var(--border)]">
        {currentPosts.map((post) => (
          <div key={post.id} className="p-5 hover:bg-[var(--background)] transition-colors cursor-pointer">
            <PostCard post={post} />
          </div>
        ))}
      </div>
    </div>
  );
}