'use client';

import { useState, useEffect } from 'react';
import { useReviewsStore } from '@/stores';
import type { Review } from '@/types/database';

const reviewTypes = ['全部', '深度评测', '对比测试', '专项测试', '用户评测'];
const sortOptions = ['最新', '评分最高', '最热'];

// Mock 数据备用
const mockReviews: Review[] = [
  { id: '1', model_id: '1', model_name: 'Claude 3.5 Sonnet', title: 'Claude 3.5 Sonnet 深度评测：编程能力质的飞跃', summary: '在编程任务中表现出色，支持200k上下文...', content: '', reviewer: 'AI评测官', rating: 5, review_type: '深度评测', tags: ['编程', '代码生成'], likes: 234, comments_count: 45, is_featured: true, status: 'published', created_at: '2026-05-02', updated_at: '' },
  { id: '2', model_id: '2', model_name: 'GPT-4 Turbo', title: 'GPT-4 Turbo vs Claude 3.5 Sonnet 全面对比', summary: 'GPT-4 Turbo 在多模态和创意写作方面仍有优势...', content: '', reviewer: '科技前沿', rating: 4.5, review_type: '对比测试', tags: ['对比评测', '多模态'], likes: 567, comments_count: 123, is_featured: false, status: 'published', created_at: '2026-05-01', updated_at: '' },
  { id: '3', model_id: '3', model_name: 'Gemini 1.5 Pro', title: 'Gemini 1.5 Pro 中文能力专项测试', summary: 'Gemini 在中文理解上有惊喜表现...', content: '', reviewer: '中文AI爱好者', rating: 4, review_type: '专项测试', tags: ['中文', '专项测试'], likes: 189, comments_count: 34, is_featured: false, status: 'published', created_at: '2026-04-30', updated_at: '' },
];

export default function ReviewPage() {
  const [activeType, setActiveType] = useState('全部');
  const [activeSort, setActiveSort] = useState('最新');
  const { reviews, isLoading, fetchReviews, getFeatured } = useReviewsStore();

  useEffect(() => {
    fetchReviews(activeType as Review['review_type'] || undefined, activeSort as '最新' | '评分最高' | '最热');
  }, [activeType, activeSort, fetchReviews]);

  const featured = getFeatured();
  const rest = featured ? reviews.filter(r => r.id !== featured.id) : reviews;

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
      {isLoading ? (
        <div className="p-8 flex items-center justify-center">
          <div className="w-8 h-8 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin"></div>
        </div>
      ) : featured ? (
        <div className="px-4 md:px-5 py-4 border-b border-[var(--border)]">
          <div className="flex items-center gap-2 mb-3">
            <span className="text-sm font-semibold text-[var(--foreground)]">⭐ 精选评测</span>
            <span className="px-1.5 py-0.5 bg-amber-100 text-amber-700 text-xs rounded font-medium">置顶</span>
          </div>
          <div className="p-4 bg-gradient-to-r from-amber-50 to-orange-50 rounded-2xl border border-amber-100 cursor-pointer hover:scale-[1.02] transition-transform">
            <div className="flex items-start gap-3">
              <div className="text-3xl">🏆</div>
              <div className="flex-1">
                <h3 className="font-bold text-[var(--foreground)] mb-1">{featured.title}</h3>
                <p className="text-sm text-[var(--text-secondary)] mb-2 line-clamp-2">{featured.summary}</p>
                <div className="flex items-center gap-3 text-xs text-[var(--text-muted)]">
                  <span>{featured.reviewer}</span>
                  <span>•</span>
                  <span>{new Date(featured.created_at).toLocaleDateString('zh-CN')}</span>
                  <span>•</span>
                  <span className="flex items-center gap-1">
                    {Array.from({ length: 5 }).map((_, i) => (
                      <span key={i} className={i < Math.floor(featured.rating) ? 'text-amber-400' : 'text-gray-200'}>★</span>
                    ))}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      ) : null}

      {/* 评测列表 */}
      <div className="divide-y divide-[var(--border)]">
        {isLoading ? (
          <div className="p-8 text-center text-[var(--text-muted)]">加载中...</div>
        ) : rest.length === 0 && !featured ? (
          // 使用 mock 数据作为备用
          mockReviews.map((review) => (
            <div
              key={review.id}
              className="px-4 md:px-5 py-4 hover:bg-[var(--background)] transition-colors cursor-pointer"
            >
              <h3 className="font-semibold text-[var(--foreground)] mb-2 leading-snug">{review.title}</h3>
              <p className="text-sm text-[var(--text-secondary)] mb-3 line-clamp-2">{review.summary}</p>
              <div className="flex flex-wrap gap-1.5 mb-3">
                {review.tags.map((tag) => (
                  <span key={tag} className="px-2 py-0.5 bg-[var(--background)] text-[var(--text-muted)] text-xs rounded">{tag}</span>
                ))}
              </div>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3 text-xs text-[var(--text-muted)]">
                  <span>{review.reviewer}</span>
                  <span>•</span>
                  <span>{new Date(review.created_at).toLocaleDateString('zh-CN')}</span>
                </div>
                <div className="flex items-center gap-4 text-xs text-[var(--text-muted)]">
                  <span>❤️ {review.likes}</span>
                  <span>💬 {review.comments_count}</span>
                </div>
              </div>
            </div>
          ))
        ) : (
          rest.map((review) => (
            <div
              key={review.id}
              className="px-4 md:px-5 py-4 hover:bg-[var(--background)] transition-colors cursor-pointer"
            >
              <h3 className="font-semibold text-[var(--foreground)] mb-2 leading-snug">{review.title}</h3>
              <p className="text-sm text-[var(--text-secondary)] mb-3 line-clamp-2">{review.summary}</p>
              <div className="flex flex-wrap gap-1.5 mb-3">
                {(review.tags || []).map((tag) => (
                  <span key={tag} className="px-2 py-0.5 bg-[var(--background)] text-[var(--text-muted)] text-xs rounded">{tag}</span>
                ))}
              </div>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3 text-xs text-[var(--text-muted)]">
                  <span>{review.reviewer}</span>
                  <span>•</span>
                  <span>{new Date(review.created_at).toLocaleDateString('zh-CN')}</span>
                </div>
                <div className="flex items-center gap-4 text-xs text-[var(--text-muted)]">
                  <span>❤️ {review.likes}</span>
                  <span>💬 {review.comments_count}</span>
                </div>
              </div>
              <div className="mt-2 flex items-center gap-1">
                <span className="text-amber-400 text-sm">
                  {Array.from({ length: 5 }).map((_, i) => (
                    <span key={i} className={i < Math.floor(review.rating) ? '' : 'text-gray-200'}>★</span>
                  ))}
                </span>
                <span className="text-sm font-medium text-[var(--foreground)] ml-1">{review.rating}</span>
                <span className="text-xs text-[var(--text-muted)]">/{review.model_name}</span>
              </div>
            </div>
          ))
        )}
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