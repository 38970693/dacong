'use client';

/**
 * ReviewsListPage - 评测文章列表页（前台）
 */
import { useState, useEffect } from 'react';
import Link from 'next/link';
import type { ReviewArticle } from '@/types/database';

interface ReviewsResponse {
  success: boolean;
  data?: ReviewArticle[];
  meta?: {
    total: number;
    limit: number;
    offset: number;
  };
  error?: string;
}

// 格式化日期
function formatDate(dateStr: string): string {
  try {
    return new Date(dateStr).toLocaleDateString('zh-CN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  } catch {
    return dateStr;
  }
}

export default function ReviewsListPage() {
  const [reviews, setReviews] = useState<ReviewArticle[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchReviews() {
      setIsLoading(true);
      setError(null);
      try {
        const res = await fetch('/api/reviews?limit=50');
        const json: ReviewsResponse = await res.json();

        if (json.success) {
          setReviews(json.data || []);
        } else {
          setError(json.error || '加载失败');
        }
      } catch (err) {
        setError('网络错误');
      } finally {
        setIsLoading(false);
      }
    }

    fetchReviews();
  }, []);

  return (
    <div className="min-h-screen bg-[var(--background)]">
      {/* 顶部区域 */}
      <div className="bg-gradient-to-br from-[var(--primary)] to-orange-600 text-white py-12 px-4">
        <div className="max-w-4xl mx-auto">
          <h1 className="text-3xl font-bold mb-2">模型评测</h1>
          <p className="text-white/80">专业评测 · 深度对比 · 客观公正</p>
        </div>
      </div>

      {/* 主内容 */}
      <main className="max-w-4xl mx-auto px-4 py-8 -mt-6">
        {/* 错误提示 */}
        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-xl text-red-600 text-sm">
            {error}
          </div>
        )}

        {/* 加载状态 */}
        {isLoading ? (
          <div className="flex items-center justify-center py-16">
            <div className="w-8 h-8 border-2 border-white border-t-transparent rounded-full animate-spin" />
          </div>
        ) : reviews.length === 0 ? (
          <div className="bg-white rounded-xl border border-[var(--border)] p-12 text-center">
            <p className="text-[var(--text-muted)] mb-4">暂无评测文章</p>
            <p className="text-sm text-[var(--text-muted)]">
              敬请期待更多精彩内容
            </p>
          </div>
        ) : (
          <div className="space-y-4">
            {reviews.map((review) => (
              <Link
                key={review.id}
                href={`/reviews/${review.slug}`}
                className="block bg-white rounded-xl border border-[var(--border)] p-5 hover:shadow-lg hover:border-[var(--primary)]/30 transition-all group"
              >
                <div className="flex gap-5">
                  {/* 封面图 */}
                  {review.cover_image && (
                    <div className="hidden sm:block w-32 h-24 rounded-lg overflow-hidden shrink-0">
                      <img
                        src={review.cover_image}
                        alt={review.title}
                        className="w-full h-full object-cover"
                      />
                    </div>
                  )}

                  {/* 内容 */}
                  <div className="flex-1 min-w-0">
                    <h2 className="text-lg font-bold text-[var(--foreground)] mb-2 group-hover:text-[var(--primary)] transition-colors line-clamp-1">
                      {review.title}
                    </h2>

                    {review.summary && (
                      <p className="text-sm text-[var(--text-secondary)] mb-3 line-clamp-2">
                        {review.summary}
                      </p>
                    )}

                    {/* 标签 */}
                    {review.tags && review.tags.length > 0 && (
                      <div className="flex flex-wrap gap-2 mb-3">
                        {review.tags.slice(0, 4).map((tag) => (
                          <span
                            key={tag}
                            className="px-2 py-0.5 bg-[var(--background)] text-[var(--text-muted)] text-xs rounded"
                          >
                            {tag}
                          </span>
                        ))}
                      </div>
                    )}

                    {/* 元信息 */}
                    <div className="flex items-center gap-4 text-xs text-[var(--text-muted)]">
                      {/* 作者 */}
                      <div className="flex items-center gap-1.5">
                        {review.author_avatar ? (
                          <img
                            src={review.author_avatar}
                            alt={review.author_name}
                            className="w-5 h-5 rounded-full"
                          />
                        ) : (
                          <div className="w-5 h-5 rounded-full bg-[var(--primary-light)] text-[var(--primary)] flex items-center justify-center text-xs font-medium">
                            {review.author_name?.charAt(0) || 'A'}
                          </div>
                        )}
                        <span>{review.author_name}</span>
                      </div>

                      {/* 日期 */}
                      <span>
                        {review.published_at
                          ? formatDate(review.published_at)
                          : formatDate(review.created_at)}
                      </span>

                      {/* 工具 */}
                      {review.tools_mentioned && review.tools_mentioned.length > 0 && (
                        <span className="hidden md:inline">
                          涉及：{review.tools_mentioned.slice(0, 3).join(', ')}
                        </span>
                      )}
                    </div>
                  </div>

                  {/* 右侧统计 */}
                  <div className="hidden sm:flex flex-col items-center justify-center gap-3 text-xs text-[var(--text-muted)] shrink-0 w-16">
                    <div className="text-center">
                      <div className="text-lg font-bold text-[var(--foreground)]">
                        {review.views || 0}
                      </div>
                      <div className="text-[10px] uppercase tracking-wider">
                        阅读
                      </div>
                    </div>
                    <div className="text-center">
                      <div className="text-lg font-bold text-[var(--foreground)]">
                        {review.likes || 0}
                      </div>
                      <div className="text-[10px] uppercase tracking-wider">
                        点赞
                      </div>
                    </div>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
