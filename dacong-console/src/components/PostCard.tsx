'use client';

import { formatDistanceToNow } from 'date-fns';
import { zhCN } from 'date-fns/locale';
import { useState, useCallback, useId } from 'react';
import { createClient } from '@supabase/supabase-js';
import { useAuthStore, useFavoritesStore, useLikesStore } from '@/stores';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByc3prZGJkZ2ZmYmRxY2xiZ29sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NzUyMDksImV4cCI6MjA5MzI1MTIwOX0.m2eElXYUlB-XHXZ8w988APQs4u1s2rn5VlIOjn2m_t0';
const supabase = createClient(supabaseUrl, supabaseKey);

interface PostCardProps {
  id: string;
  title: string;
  content: string | null;
  source: string | null;
  source_url: string | null;
  views: number;
  likes: number;
  comments_count: number;
  created_at: string;
  onLoginRequired?: () => void;
}

function formatNumber(n: number): string {
  if (n >= 10000) return (n / 10000).toFixed(1) + 'w';
  if (n >= 1000) return (n / 1000).toFixed(1) + 'k';
  return n.toString();
}

function formatTime(dateStr: string): string {
  try {
    return formatDistanceToNow(new Date(dateStr), { addSuffix: true, locale: zhCN });
  } catch {
    return '刚刚';
  }
}

export function PostCard({ post, onLoginRequired }: { post: PostCardProps; onLoginRequired?: () => void }) {
  const { user } = useAuthStore();
  const { isFavorited, addFavorite, removeFavorite } = useFavoritesStore();
  const { isLiked, like, unlike } = useLikesStore();

  const [likeCount, setLikeCount] = useState(post.likes || 0);
  const [isLiking, setIsLiking] = useState(false);

  // 同步数据库中的点赞数到本地状态
  const userHasLiked = isLiked('post', post.id);
  const userHasFavorited = isFavorited('post', post.id);

  const handleLike = useCallback(async (e: React.MouseEvent) => {
    e.stopPropagation();

    // 未登录时提示登录
    if (!user) {
      onLoginRequired?.();
      return;
    }

    if (isLiking) return;
    setIsLiking(true);

    const wasLiked = userHasLiked;

    try {
      // 乐观更新 UI
      setLikeCount(wasLiked ? likeCount - 1 : likeCount + 1);

      // 更新数据库和 likes 表
      const newCount = wasLiked ? likeCount - 1 : likeCount + 1;

      // 更新帖子点赞数
      const { error: postError } = await supabase
        .from('posts')
        .update({ likes: newCount })
        .eq('id', post.id);

      if (postError) {
        throw new Error(postError.message);
      }

      // 更新用户点赞记录
      if (wasLiked) {
        await unlike(user.id, 'post', post.id);
      } else {
        await like(user.id, 'post', post.id);
      }
    } catch (err) {
      // 回滚 UI
      setLikeCount(likeCount);
      console.error('点赞失败:', err);
    } finally {
      setIsLiking(false);
    }
  }, [user, userHasLiked, isLiking, likeCount, post.id, onLoginRequired, like, unlike]);

  const handleFavorite = useCallback(async (e: React.MouseEvent) => {
    e.stopPropagation();

    // 未登录时提示登录
    if (!user) {
      onLoginRequired?.();
      return;
    }

    const wasFavorited = userHasFavorited;

    try {
      if (wasFavorited) {
        await removeFavorite(user.id, 'post', post.id);
      } else {
        await addFavorite(user.id, 'post', post.id);
      }
    } catch (err) {
      console.error('收藏操作失败:', err);
    }
  }, [user, userHasFavorited, post.id, onLoginRequired, addFavorite, removeFavorite]);

  return (
    <article className="bg-white rounded-2xl p-5 mb-4 border border-[var(--border)] card-hover shadow-sm">
      {/* 来源标签 */}
      {post.source && (
        <div className="mb-3">
          <span className="tag">
            {post.source}
          </span>
        </div>
      )}

      {/* 标题 */}
      <h3 className="text-lg font-bold text-[var(--foreground)] mb-2 line-clamp-2 leading-snug">
        {post.title}
      </h3>

      {/* 内容预览 */}
      {post.content && (
        <p className="text-sm text-[var(--text-secondary)] mb-4 line-clamp-2 leading-relaxed">
          {post.content}
        </p>
      )}

      {/* 底部信息栏 */}
      <div className="flex items-center justify-between pt-3 border-t border-[var(--border)]">
        {/* 时间 */}
        <span className="text-xs text-[var(--text-muted)]">{formatTime(post.created_at)}</span>

        {/* 互动数据 */}
        <div className="flex items-center gap-5">
          {/* 浏览数 */}
          <button className="flex items-center gap-1.5 text-[var(--text-muted)] hover:text-[var(--primary)] transition-colors group" aria-label={`浏览次数 ${post.views}`}>
            <svg className="w-4 h-4 group-hover:scale-110 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5} aria-hidden="true">
              <path strokeLinecap="round" strokeLinejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
              <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <span className="text-xs font-medium" aria-hidden="true">{formatNumber(post.views)}</span>
          </button>

          {/* 点赞按钮 */}
          <button
            onClick={handleLike}
            aria-label={userHasLiked ? `取消点赞，当前点赞数 ${likeCount}` : `点赞，点赞数 ${likeCount}`}
            aria-pressed={userHasLiked}
            className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-full transition-all ${
              userHasLiked
                ? 'bg-red-50 text-red-500'
                : 'bg-transparent text-[var(--text-muted)] hover:text-red-500'
            }`}
          >
            <svg
              className={`w-4 h-4 transition-transform ${userHasLiked ? 'fill-current scale-110' : ''}`}
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={1.5}
              aria-hidden="true"
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z" />
            </svg>
            <span className="text-xs font-medium" aria-hidden="true">{formatNumber(likeCount)}</span>
          </button>

          {/* 收藏按钮 */}
          <button
            onClick={handleFavorite}
            aria-label={userHasFavorited ? '取消收藏' : '收藏'}
            aria-pressed={userHasFavorited}
            className={`flex items-center gap-1.5 px-2.5 py-1.5 rounded-full transition-all ${
              userHasFavorited
                ? 'bg-yellow-50 text-yellow-600'
                : 'bg-transparent text-[var(--text-muted)] hover:text-yellow-600'
            }`}
          >
            <svg
              className={`w-4 h-4 transition-transform ${userHasFavorited ? 'fill-current' : ''}`}
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={1.5}
              aria-hidden="true"
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M17.593 3.322c1.1.128 1.907 1.077 1.907 2.185V21L12 17.25 4.5 21V5.507c0-1.108.806-2.057 1.907-2.185a48.507 48.507 0 0111.186 0z" />
            </svg>
          </button>

          {/* 评论数 */}
          <button className="flex items-center gap-1.5 text-[var(--text-muted)] hover:text-[var(--primary)] transition-colors group" aria-label={`评论数 ${post.comments_count}`}>
            <svg className="w-4 h-4 group-hover:scale-110 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5} aria-hidden="true">
              <path strokeLinecap="round" strokeLinejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
            </svg>
            <span className="text-xs font-medium" aria-hidden="true">{formatNumber(post.comments_count)}</span>
          </button>
        </div>
      </div>

      {/* 来源链接 */}
      {post.source_url && (
        <a
          href={post.source_url}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-1 mt-3 text-xs text-[var(--primary)] hover:underline font-medium"
        >
          阅读原文
          <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 6H5.25A2.25 2.25 0 003 8.25v10.5A2.25 2.25 0 005.25 21h10.5A2.25 2.25 0 0018 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" />
          </svg>
        </a>
      )}
    </article>
  );
}