'use client';

import { useEffect, useState, useCallback } from 'react';
import { usePostsStore } from '@/stores';
import { PostCard } from '@/components/PostCard';

const REFRESH_INTERVAL = 10 * 60 * 1000; // 10分钟刷新一次

export default function HomePage() {
  const { posts, isLoading, error, fetchPosts, hasMore, loadMore } = usePostsStore();
  const [isRefreshing, setIsRefreshing] = useState(false);

  // 初始化加载
  useEffect(() => {
    fetchPosts();
  }, [fetchPosts]);

  // 自动刷新
  useEffect(() => {
    const interval = setInterval(() => {
      fetchPosts();
    }, REFRESH_INTERVAL);

    return () => clearInterval(interval);
  }, [fetchPosts]);

  // 手动刷新
  const handleRefresh = useCallback(async () => {
    setIsRefreshing(true);
    await fetchPosts();
    setIsRefreshing(false);
  }, [fetchPosts]);

  // 无限滚动加载更多
  useEffect(() => {
    const handleScroll = () => {
      if (
        window.innerHeight + window.scrollY >= document.body.offsetHeight - 500 &&
        hasMore &&
        !isLoading
      ) {
        loadMore();
      }
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, [hasMore, isLoading, loadMore]);

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] px-4">
        <p className="text-[var(--text-secondary)] mb-4">{error}</p>
        <button
          onClick={handleRefresh}
          className="px-6 py-2.5 bg-[var(--primary)] text-white rounded-full font-medium"
        >
          重试
        </button>
      </div>
    );
  }

  return (
    <div className="pb-16 md:pb-0">
      {/* 刷新状态提示 */}
      {isRefreshing && (
        <div className="sticky top-0 z-20 bg-[var(--primary)] text-white text-sm text-center py-1.5">
          正在刷新...
        </div>
      )}

      {/* 帖子列表 */}
      <div className="divide-y divide-[var(--border)]">
        {posts.map((post, index) => (
          <div
            key={post.id}
            className="p-4 md:p-5 hover:bg-[var(--background)] transition-colors cursor-pointer"
            style={{ animationDelay: `${index * 50}ms` }}
          >
            <PostCard post={post} />
          </div>
        ))}
      </div>

      {/* 加载状态 */}
      <div className="p-6 md:p-8 text-center">
        {isLoading && !isRefreshing ? (
          <div className="flex items-center justify-center gap-3">
            <div className="loading-spinner" />
            <span className="text-sm text-[var(--text-secondary)]">加载中...</span>
          </div>
        ) : !hasMore && posts.length > 0 ? (
          <div className="flex items-center justify-center gap-2 text-sm text-[var(--text-muted)]">
            <span className="w-8 h-px bg-[var(--border)]"></span>
            <span>没有更多了</span>
            <span className="w-8 h-px bg-[var(--border)]"></span>
          </div>
        ) : null}
      </div>
    </div>
  );
}