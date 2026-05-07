'use client';

/**
 * AdminReviewsPage - 评测文章管理列表
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

export default function AdminReviewsPage() {
  const [reviews, setReviews] = useState<ReviewArticle[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showAll, setShowAll] = useState(false); // 是否显示所有（包括草稿）

  useEffect(() => {
    async function fetchReviews() {
      setIsLoading(true);
      setError(null);
      try {
        const url = showAll ? '?published=all' : '';
        const res = await fetch(`/api/reviews${url}`);
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
  }, [showAll]);

  const handleDelete = async (id: string, title: string) => {
    if (!confirm(`确定要删除文章「${title}」吗？此操作不可恢复。`)) {
      return;
    }

    try {
      const res = await fetch(`/api/reviews/${id}`, {
        method: 'DELETE',
      });
      const json = await res.json();

      if (json.success) {
        setReviews(reviews.filter((r) => r.id !== id));
      } else {
        alert(json.error || '删除失败');
      }
    } catch (err) {
      alert('删除失败');
    }
  };

  return (
    <div>
      {/* 页面标题 */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-[var(--foreground)]">评测文章</h1>
          <p className="text-sm text-[var(--text-muted)] mt-1">
            {showAll ? '显示全部' : '仅显示已发布'} · 共 {reviews.length} 篇
          </p>
        </div>
        <div className="flex items-center gap-3">
          <label className="flex items-center gap-2 text-sm text-[var(--text-secondary)]">
            <input
              type="checkbox"
              checked={showAll}
              onChange={(e) => setShowAll(e.target.checked)}
              className="w-4 h-4 rounded border-[var(--border)] text-[var(--primary)] focus:ring-[var(--primary)]"
            />
            显示全部（包括草稿）
          </label>
          <Link
            href="/admin/reviews/new"
            className="px-4 py-2 bg-[var(--primary)] text-white rounded-lg text-sm font-medium hover:bg-[var(--primary-dark)] transition-colors"
          >
            新建文章
          </Link>
        </div>
      </div>

      {/* 错误提示 */}
      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-xl text-red-600 text-sm">
          {error}
        </div>
      )}

      {/* 加载状态 */}
      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <div className="w-8 h-8 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin" />
        </div>
      ) : reviews.length === 0 ? (
        <div className="bg-white rounded-xl border border-[var(--border)] p-12 text-center">
          <p className="text-[var(--text-muted)] mb-4">还没有评测文章</p>
          <Link
            href="/admin/reviews/new"
            className="inline-block px-4 py-2 bg-[var(--primary)] text-white rounded-lg text-sm font-medium hover:bg-[var(--primary-dark)] transition-colors"
          >
            创建第一篇
          </Link>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-[var(--border)] overflow-hidden">
          <table className="w-full">
            <thead className="bg-[var(--background)] border-b border-[var(--border)]">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-medium text-[var(--text-muted)] uppercase tracking-wider">
                  标题
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-[var(--text-muted)] uppercase tracking-wider">
                  作者
                </th>
                <th className="px-4 py-3 text-left text-xs font-medium text-[var(--text-muted)] uppercase tracking-wider">
                  标签
                </th>
                <th className="px-4 py-3 text-center text-xs font-medium text-[var(--text-muted)] uppercase tracking-wider">
                  状态
                </th>
                <th className="px-4 py-3 text-center text-xs font-medium text-[var(--text-muted)] uppercase tracking-wider">
                  浏览
                </th>
                <th className="px-4 py-3 text-center text-xs font-medium text-[var(--text-muted)] uppercase tracking-wider">
                  点赞
                </th>
                <th className="px-4 py-3 text-right text-xs font-medium text-[var(--text-muted)] uppercase tracking-wider">
                  操作
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[var(--border)]">
              {reviews.map((review) => (
                <tr key={review.id} className="hover:bg-[var(--background)] transition-colors">
                  <td className="px-4 py-3">
                    <div className="max-w-xs">
                      <Link
                        href={`/admin/reviews/${review.id}/edit`}
                        className="font-medium text-[var(--foreground)] hover:text-[var(--primary)] line-clamp-1"
                      >
                        {review.title}
                      </Link>
                      <p className="text-xs text-[var(--text-muted)] mt-0.5">
                        /{review.slug}
                      </p>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-2">
                      <div className="w-6 h-6 rounded-full bg-[var(--primary-light)] text-[var(--primary)] flex items-center justify-center text-xs font-medium">
                        {review.author_name?.charAt(0) || 'A'}
                      </div>
                      <span className="text-sm text-[var(--text-secondary)]">
                        {review.author_name}
                      </span>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex flex-wrap gap-1">
                      {(review.tags || []).slice(0, 2).map((tag) => (
                        <span
                          key={tag}
                          className="px-2 py-0.5 bg-[var(--background)] text-[var(--text-muted)] text-xs rounded"
                        >
                          {tag}
                        </span>
                      ))}
                      {(review.tags || []).length > 2 && (
                        <span className="px-2 py-0.5 text-[var(--text-muted)] text-xs">
                          +{review.tags.length - 2}
                        </span>
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-3 text-center">
                    <span
                      className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${
                        review.published
                          ? 'bg-green-100 text-green-700'
                          : 'bg-gray-100 text-gray-600'
                      }`}
                    >
                      {review.published ? '已发布' : '草稿'}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-center text-sm text-[var(--text-muted)]">
                    {review.views || 0}
                  </td>
                  <td className="px-4 py-3 text-center text-sm text-[var(--text-muted)]">
                    {review.likes || 0}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <div className="flex items-center justify-end gap-2">
                      {review.published && (
                        <Link
                          href={`/reviews/${review.slug}`}
                          target="_blank"
                          className="p-2 text-[var(--text-muted)] hover:text-[var(--primary)] transition-colors"
                          title="预览"
                        >
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                            <path strokeLinecap="round" strokeLinejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                          </svg>
                        </Link>
                      )}
                      <Link
                        href={`/admin/reviews/${review.id}/edit`}
                        className="p-2 text-[var(--text-muted)] hover:text-[var(--primary)] transition-colors"
                        title="编辑"
                      >
                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                        </svg>
                      </Link>
                      <button
                        onClick={() => handleDelete(review.id, review.title)}
                        className="p-2 text-[var(--text-muted)] hover:text-red-500 transition-colors"
                        title="删除"
                      >
                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
