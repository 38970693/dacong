'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useReviewsStore, useAuthStore, useLikesStore, useFavoritesStore } from '@/stores';
import type { Review } from '@/types/database';

export default function ReviewDetailClient() {
  const params = useParams();
  const router = useRouter();
  const id = params.id as string;
  const { currentReview, isLoading, fetchReviewById } = useReviewsStore();
  const { user } = useAuthStore();
  const { isLiked, like, unlike } = useLikesStore();
  const { isFavorited, addFavorite, removeFavorite } = useFavoritesStore();

  const [likeCount, setLikeCount] = useState(0);

  useEffect(() => {
    if (id) {
      fetchReviewById(id);
    }
  }, [id, fetchReviewById]);

  useEffect(() => {
    if (currentReview) {
      setLikeCount(currentReview.likes || 0);
    }
  }, [currentReview]);

  const userHasLiked = isLiked('review', id);
  const userHasFavorited = isFavorited('review', id);

  const handleLike = async () => {
    if (!user) {
      alert('请先登录');
      return;
    }

    const wasLiked = userHasLiked;
    setLikeCount(wasLiked ? likeCount - 1 : likeCount + 1);

    try {
      if (wasLiked) {
        await unlike(user.id, 'review', id);
      } else {
        await like(user.id, 'review', id);
      }
    } catch (err) {
      setLikeCount(likeCount);
      console.error('点赞失败:', err);
    }
  };

  const handleFavorite = async () => {
    if (!user) {
      alert('请先登录');
      return;
    }

    try {
      if (userHasFavorited) {
        await removeFavorite(user.id, 'review', id);
      } else {
        await addFavorite(user.id, 'review', id);
      }
    } catch (err) {
      console.error('收藏失败:', err);
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  if (!currentReview) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center gap-4">
        <p className="text-[var(--text-muted)]">评测不存在</p>
        <button
          onClick={() => router.push('/web/review')}
          className="px-4 py-2 bg-[var(--primary)] text-white rounded-full text-sm"
        >
          返回评测列表
        </button>
      </div>
    );
  }

  return (
    <div className="pb-20 md:pb-8">
      {/* 返回按钮 */}
      <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 border-b border-[var(--border)]">
        <button
          onClick={() => router.back()}
          className="flex items-center gap-2 text-sm text-[var(--text-secondary)] hover:text-[var(--foreground)]"
        >
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
          </svg>
          返回
        </button>
      </div>

      {/* 评测内容 */}
      <article className="px-4 md:px-5 py-6">
        {/* 头部信息 */}
        <div className="mb-6">
          {/* 标签 */}
          <div className="flex items-center gap-2 mb-3">
            <span className="px-3 py-1 bg-[var(--background)] text-[var(--text-secondary)] text-xs rounded-full">
              {currentReview.review_type}
            </span>
            {currentReview.is_featured && (
              <span className="px-3 py-1 bg-amber-100 text-amber-700 text-xs rounded-full font-medium">
                ⭐ 精选
              </span>
            )}
          </div>

          {/* 标题 */}
          <h1 className="text-2xl font-bold text-[var(--foreground)] mb-4 leading-snug">
            {currentReview.title}
          </h1>

          {/* 模型和评分 */}
          <div className="flex items-center gap-4 mb-4">
            <div className="text-sm text-[var(--text-secondary)]">
              评测模型：<span className="font-medium text-[var(--foreground)]">{currentReview.model_name}</span>
            </div>
            <div className="flex items-center gap-1">
              <span className="text-amber-400">
                {Array.from({ length: 5 }).map((_, i) => (
                  <span key={i} className={i < Math.floor(currentReview.rating) ? '' : 'text-gray-200'}>★</span>
                ))}
              </span>
              <span className="font-bold text-lg text-[var(--foreground)] ml-1">{currentReview.rating}</span>
            </div>
          </div>

          {/* 作者和日期 */}
          <div className="flex items-center gap-4 text-sm text-[var(--text-muted)]">
            <span>作者：{currentReview.reviewer}</span>
            <span>•</span>
            <span>{new Date(currentReview.created_at).toLocaleDateString('zh-CN')}</span>
          </div>
        </div>

        {/* 摘要 */}
        {currentReview.summary && (
          <div className="p-4 bg-[var(--background)] rounded-2xl mb-6">
            <p className="text-[var(--text-secondary)] leading-relaxed">{currentReview.summary}</p>
          </div>
        )}

        {/* 内容 */}
        <div className="prose prose-slate max-w-none mb-8">
          {currentReview.content ? (
            <div className="whitespace-pre-wrap text-[var(--text-secondary)] leading-relaxed">
              {currentReview.content}
            </div>
          ) : (
            <p className="text-[var(--text-muted)]">暂无内容</p>
          )}
        </div>

        {/* 标签 */}
        {currentReview.tags && currentReview.tags.length > 0 && (
          <div className="flex flex-wrap gap-2 mb-6">
            {currentReview.tags.map((tag) => (
              <span
                key={tag}
                className="px-3 py-1 bg-[var(--background)] text-[var(--text-muted)] text-sm rounded-full"
              >
                #{tag}
              </span>
            ))}
          </div>
        )}

        {/* 互动栏 */}
        <div className="flex items-center gap-4 pt-4 border-t border-[var(--border)]">
          <button
            onClick={handleLike}
            className={`flex items-center gap-2 px-4 py-2 rounded-full transition-all ${
              userHasLiked
                ? 'bg-red-50 text-red-500 border border-red-200'
                : 'bg-white text-[var(--text-muted)] border border-[var(--border)] hover:border-red-300'
            }`}
          >
            <span className={userHasLiked ? 'text-red-500' : ''}>❤️</span>
            <span className="text-sm font-medium">{likeCount}</span>
          </button>

          <button
            onClick={handleFavorite}
            className={`flex items-center gap-2 px-4 py-2 rounded-full transition-all ${
              userHasFavorited
                ? 'bg-yellow-50 text-yellow-600 border border-yellow-200'
                : 'bg-white text-[var(--text-muted)] border border-[var(--border)] hover:border-yellow-300'
            }`}
          >
            <span>{userHasFavorited ? '★' : '☆'}</span>
            <span className="text-sm font-medium">{userHasFavorited ? '已收藏' : '收藏'}</span>
          </button>

          <div className="ml-auto text-sm text-[var(--text-muted)]">
            💬 {currentReview.comments_count || 0} 评论
          </div>
        </div>
      </article>
    </div>
  );
}