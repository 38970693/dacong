'use client';

import { useState } from 'react';

interface Review {
  id: string;
  title: string;
  model: string;
  reviewer: string;
  rating: number;
  date: string;
  summary: string;
  tags: string[];
  likes: number;
  comments: number;
}

const mockReviews: Review[] = [
  {
    id: '1',
    title: 'Claude 3.5 Sonnet 深度评测：编程能力质的飞跃',
    model: 'Claude 3.5 Sonnet',
    reviewer: 'AI评测官',
    rating: 5,
    date: '2026-05-02',
    summary: '在编程任务中表现出色，支持200k上下文，能够快速理解项目结构并提供高质量代码建议...',
    tags: ['编程', '代码生成', '深度评测'],
    likes: 234,
    comments: 45,
  },
  {
    id: '2',
    title: 'GPT-4 Turbo vs Claude 3.5 Sonnet 全面对比',
    model: 'GPT-4 Turbo',
    reviewer: '科技前沿',
    rating: 4.5,
    date: '2026-05-01',
    summary: 'GPT-4 Turbo 在多模态和创意写作方面仍有优势，但 Claude 在性价比和编程辅助上更胜一筹...',
    tags: ['对比评测', '多模态', '创意写作'],
    likes: 567,
    comments: 123,
  },
  {
    id: '3',
    title: 'Gemini 1.5 Pro 中文能力专项测试',
    model: 'Gemini 1.5 Pro',
    reviewer: '中文AI爱好者',
    rating: 4,
    date: '2026-04-30',
    summary: 'Gemini 在中文理解上有惊喜表现，但在某些特定领域的专业术语上仍有提升空间...',
    tags: ['中文', '专项测试', '本地化'],
    likes: 189,
    comments: 34,
  },
  {
    id: '4',
    title: 'Llama 3.1 405B 开源最强音评测',
    model: 'Llama 3.1 405B',
    reviewer: '开源社区',
    rating: 4.5,
    date: '2026-04-28',
    summary: '作为当前最强的开源模型，Llama 3.1 405B 在多项基准测试中逼近闭源模型，但部署成本较高...',
    tags: ['开源', 'LLM', '部署'],
    likes: 423,
    comments: 89,
  },
];

const reviewTypes = ['全部', '深度评测', '对比测试', '专项测试', '用户评测'];
const sortOptions = ['最新', '最热', '评分最高'];

export default function ReviewPage() {
  const [activeType, setActiveType] = useState('全部');
  const [activeSort, setActiveSort] = useState('最新');

  return (
    <div className="pb-16 md:pb-0">
      {/* 页面标题 */}
      <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        <h1 className="text-lg font-bold text-[var(--foreground)] flex items-center gap-2">
          <span>📝</span>
          <span>模型评测</span>
        </h1>
        <p className="text-xs text-[var(--text-muted)] hidden md:block">专业评测 · 深度对比 · 客观公正</p>
      </div>

      {/* 筛选栏 */}
      <div className="px-4 md:px-5 py-3 border-b border-[var(--border)] space-y-3">
        {/* 评测类型 */}
        <div className="flex gap-2 overflow-x-auto pb-1">
          {reviewTypes.map((type) => (
            <button
              key={type}
              onClick={() => setActiveType(type)}
              className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap transition-all shrink-0 ${
                activeType === type
                  ? 'bg-[var(--foreground)] text-white'
                  : 'bg-white border border-[var(--border)] text-[var(--text-secondary)] hover:border-[var(--foreground)]'
              }`}
            >
              {type}
            </button>
          ))}
        </div>

        {/* 排序选项 */}
        <div className="flex items-center gap-2">
          <span className="text-xs text-[var(--text-muted)]">排序：</span>
          <div className="flex gap-2">
            {sortOptions.map((option) => (
              <button
                key={option}
                onClick={() => setActiveSort(option)}
                className={`px-3 py-1 rounded text-xs font-medium transition-all ${
                  activeSort === option
                    ? 'bg-[var(--primary-light)] text-[var(--primary)]'
                    : 'text-[var(--text-muted)] hover:text-[var(--foreground)]'
                }`}
              >
                {option}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* 精选评测 */}
      <div className="px-4 md:px-5 py-4 border-b border-[var(--border)]">
        <div className="flex items-center gap-2 mb-3">
          <span className="text-sm font-semibold text-[var(--foreground)]">⭐ 精选评测</span>
          <span className="px-1.5 py-0.5 bg-amber-100 text-amber-700 text-xs rounded font-medium">置顶</span>
        </div>
        <div className="p-4 bg-gradient-to-r from-amber-50 to-orange-50 rounded-2xl border border-amber-100">
          <div className="flex items-start gap-3">
            <div className="text-3xl">🏆</div>
            <div className="flex-1">
              <h3 className="font-bold text-[var(--foreground)] mb-1">{mockReviews[0].title}</h3>
              <p className="text-sm text-[var(--text-secondary)] mb-2 line-clamp-2">{mockReviews[0].summary}</p>
              <div className="flex items-center gap-3 text-xs text-[var(--text-muted)]">
                <span>{mockReviews[0].reviewer}</span>
                <span>•</span>
                <span>{mockReviews[0].date}</span>
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
      <div className="divide-y divide-[var(--border)]">
        {mockReviews.slice(1).map((review) => (
          <div
            key={review.id}
            className="px-4 md:px-5 py-4 hover:bg-[var(--background)] transition-colors cursor-pointer"
          >
            {/* 标题 */}
            <h3 className="font-semibold text-[var(--foreground)] mb-2 leading-snug">{review.title}</h3>

            {/* 摘要 */}
            <p className="text-sm text-[var(--text-secondary)] mb-3 line-clamp-2">{review.summary}</p>

            {/* 标签 */}
            <div className="flex flex-wrap gap-1.5 mb-3">
              {review.tags.map((tag) => (
                <span key={tag} className="px-2 py-0.5 bg-[var(--background)] text-[var(--text-muted)] text-xs rounded">
                  {tag}
                </span>
              ))}
            </div>

            {/* 元信息 */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3 text-xs text-[var(--text-muted)]">
                <span>{review.reviewer}</span>
                <span>•</span>
                <span>{review.date}</span>
              </div>
              <div className="flex items-center gap-4 text-xs text-[var(--text-muted)]">
                <span className="flex items-center gap-1">
                  <span>❤️</span> {review.likes}
                </span>
                <span className="flex items-center gap-1">
                  <span>💬</span> {review.comments}
                </span>
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
              <span className="text-xs text-[var(--text-muted)]">/{review.model}</span>
            </div>
          </div>
        ))}
      </div>

      {/* 查看更多 */}
      <div className="p-6 md:p-8 text-center">
        <button className="px-6 py-2.5 bg-white border border-[var(--border)] text-[var(--foreground)] rounded-full text-sm font-medium hover:bg-[var(--background)] transition-all">
          加载更多 →
        </button>
      </div>
    </div>
  );
}