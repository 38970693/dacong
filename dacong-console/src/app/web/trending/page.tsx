'use client';

import { useState } from 'react';
import Link from 'next/link';
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

const mockReviews = [
  {
    id: 'r1',
    model_name: 'Claude 3.5 Sonnet',
    title: 'Claude 3.5 Sonnet 深度评测：编程能力质的飞跃',
    summary: '在编程任务中表现出色，支持200k上下文，能够快速理解项目结构并提供高质量代码建议...',
    reviewer: 'AI评测官',
    rating: 5,
    likes: 234,
    comments_count: 45,
    created_at: '2026-05-02',
  },
  {
    id: 'r2',
    model_name: 'GPT-4 Turbo',
    title: 'GPT-4 Turbo vs Claude 3.5 Sonnet 全面对比',
    summary: 'GPT-4 Turbo 在多模态和创意写作方面仍有优势，但 Claude 在性价比和编程辅助上更胜一筹...',
    reviewer: '科技前沿',
    rating: 4.5,
    likes: 567,
    comments_count: 123,
    created_at: '2026-05-01',
  },
  {
    id: 'r3',
    model_name: 'Gemini 1.5 Pro',
    title: 'Gemini 1.5 Pro 中文能力专项测试',
    summary: 'Gemini 在中文理解上有惊喜表现，但在某些特定领域的专业术语上仍有提升空间...',
    reviewer: '中文AI爱好者',
    rating: 4,
    likes: 189,
    comments_count: 34,
    created_at: '2026-04-30',
  },
];

type TabType = 'hot' | 'new' | 'review';

export default function TrendingPage() {
  const [activeTab, setActiveTab] = useState<TabType>('hot');
  const currentPosts = activeTab === 'hot' ? mockHotPosts : activeTab === 'new' ? mockNewPosts : [];

  // 特殊大按钮点击处理
  const handleSpecialAction = () => {
    // 跳转到评测页面或打开编辑器
    window.location.href = '/web/review';
  };

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

      {/* 标签切换 - 中间带特殊按钮 */}
      <div className="flex items-center gap-2 md:gap-3 px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        {/* 热榜标签 */}
        <button
          onClick={() => setActiveTab('hot')}
          className={`px-4 md:px-5 py-2 rounded-full text-sm font-semibold transition-all ${
            activeTab === 'hot'
              ? 'bg-[var(--primary)] text-white shadow-lg shadow-[var(--primary)]/30'
              : 'bg-white text-[var(--text-secondary)] border border-[var(--border)] hover:border-[var(--primary)] hover:text-[var(--primary)]'
          }`}
        >
          🌡️ 热榜
        </button>

        {/* 最新标签 */}
        <button
          onClick={() => setActiveTab('new')}
          className={`px-4 md:px-5 py-2 rounded-full text-sm font-semibold transition-all ${
            activeTab === 'new'
              ? 'bg-[var(--primary)] text-white shadow-lg shadow-[var(--primary)]/30'
              : 'bg-white text-[var(--text-secondary)] border border-[var(--border)] hover:border-[var(--primary)] hover:text-[var(--primary)]'
          }`}
        >
          ✨ 最新
        </button>

        {/* 特殊大按钮 - 中间位置 */}
        <button
          onClick={handleSpecialAction}
          className="flex-1 mx-2 md:mx-4 py-3 px-6 bg-gradient-to-r from-[var(--primary)] to-[var(--primary-dark)] text-white rounded-2xl font-bold text-sm md:text-base shadow-lg shadow-[var(--primary)]/30 hover:shadow-xl hover:scale-[1.02] transition-all flex items-center justify-center gap-2"
        >
          <span className="text-lg">✍️</span>
          <span>写评测</span>
        </button>

        {/* 评测标签 */}
        <button
          onClick={() => setActiveTab('review')}
          className={`px-4 md:px-5 py-2 rounded-full text-sm font-semibold transition-all ${
            activeTab === 'review'
              ? 'bg-[var(--primary)] text-white shadow-lg shadow-[var(--primary)]/30'
              : 'bg-white text-[var(--text-secondary)] border border-[var(--border)] hover:border-[var(--primary)] hover:text-[var(--primary)]'
          }`}
        >
          📝 评测
        </button>
      </div>

      {/* 热榜/最新 内容 */}
      {(activeTab === 'hot' || activeTab === 'new') && (
        <>
          {/* TOP 3 展示 - 仅热榜显示 */}
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
        </>
      )}

      {/* 评测内容 */}
      {activeTab === 'review' && (
        <div className="divide-y divide-[var(--border)]">
          {/* 精选评测 */}
          <div className="px-4 md:px-5 py-4 border-b border-[var(--border)]">
            <div className="flex items-center gap-2 mb-3">
              <span className="text-sm font-semibold text-[var(--foreground)]">⭐ 精选评测</span>
              <span className="px-1.5 py-0.5 bg-amber-100 text-amber-700 text-xs rounded font-medium">置顶</span>
            </div>
            <div className="p-4 bg-gradient-to-r from-amber-50 to-orange-50 rounded-2xl border border-amber-100 cursor-pointer hover:scale-[1.01] transition-transform">
              <div className="flex items-start gap-3">
                <div className="text-3xl">🏆</div>
                <div className="flex-1">
                  <h3 className="font-bold text-[var(--foreground)] mb-1">{mockReviews[0].title}</h3>
                  <p className="text-sm text-[var(--text-secondary)] mb-2 line-clamp-2">{mockReviews[0].summary}</p>
                  <div className="flex items-center gap-3 text-xs text-[var(--text-muted)]">
                    <span>{mockReviews[0].reviewer}</span>
                    <span>•</span>
                    <span>{mockReviews[0].model_name}</span>
                    <span>•</span>
                    <span className="flex items-center gap-1">
                      {Array.from({ length: 5 }).map((_, i) => (
                        <span key={i} className={i < Math.floor(mockReviews[0].rating) ? 'text-amber-400' : 'text-gray-200'}>★</span>
                      ))}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* 评测列表 */}
          {mockReviews.slice(1).map((review) => (
            <div
              key={review.id}
              className="px-4 md:px-5 py-4 hover:bg-[var(--background)] transition-colors cursor-pointer"
            >
              {/* 模型名 + 标题 */}
              <div className="flex items-center gap-2 mb-2">
                <span className="px-2 py-0.5 bg-[var(--primary-light)] text-[var(--primary)] text-xs rounded-full font-medium">
                  {review.model_name}
                </span>
              </div>
              <h3 className="font-semibold text-[var(--foreground)] mb-2 leading-snug">{review.title}</h3>

              {/* 摘要 */}
              <p className="text-sm text-[var(--text-secondary)] mb-3 line-clamp-2">{review.summary}</p>

              {/* 元信息 */}
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3 text-xs text-[var(--text-muted)]">
                  <span>{review.reviewer}</span>
                  <span>•</span>
                  <span>{new Date(review.created_at).toLocaleDateString('zh-CN')}</span>
                </div>
                <div className="flex items-center gap-4 text-xs text-[var(--text-muted)]">
                  <span className="flex items-center gap-1">❤️ {review.likes}</span>
                  <span className="flex items-center gap-1">💬 {review.comments_count}</span>
                </div>
              </div>

              {/* 评分 */}
              <div className="mt-2 flex items-center gap-1">
                <span className="text-amber-400 text-sm">
                  {Array.from({ length: 5 }).map((_, i) => (
                    <span key={i} className={i < Math.floor(review.rating) ? '' : 'text-gray-200'}>★</span>
                  ))}
                </span>
                <span className="text-sm font-medium text-[var(--foreground)] ml-1">{review.rating}</span>
              </div>
            </div>
          ))}

          {/* 查看更多 */}
          <div className="p-6 md:p-8 text-center">
            <button className="px-6 py-2.5 bg-white border border-[var(--border)] text-[var(--foreground)] rounded-full text-sm font-medium hover:bg-[var(--background)] transition-all">
              加载更多 →
            </button>
          </div>
        </div>
      )}
    </div>
  );
}