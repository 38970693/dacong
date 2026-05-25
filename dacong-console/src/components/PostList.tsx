'use client';

import { useEffect, useRef, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { usePostsStore } from '@/stores';
import { PostCard } from './PostCard';

export function PostList() {
  const router = useRouter();
  const { posts, isLoading, error, hasMore, fetchPosts, loadMore, refresh } = usePostsStore();
  const loaderRef = useRef<HTMLDivElement>(null);

  // 帖子点击跳转
  const handlePostClick = useCallback((postId: string) => {
    router.push(`/web/post/${postId}`);
  }, [router]);

  // 初始化加载
  useEffect(() => {
    if (posts.length === 0) {
      fetchPosts();
    }
  }, [posts.length, fetchPosts]);

  // 无限滚动
  const handleObserver = useCallback(
    (entries: IntersectionObserverEntry[]) => {
      const [entry] = entries;
      if (entry.isIntersecting && hasMore && !isLoading) {
        loadMore();
      }
    },
    [hasMore, isLoading, loadMore]
  );

  useEffect(() => {
    const observer = new IntersectionObserver(handleObserver, {
      threshold: 0.1,
      rootMargin: '100px'
    });

    if (loaderRef.current) {
      observer.observe(loaderRef.current);
    }

    return () => observer.disconnect();
  }, [handleObserver]);

  if (error) {
    return (
      <div className="empty-state">
        <div className="w-16 h-16 mb-4 rounded-full bg-[var(--primary-light)] flex items-center justify-center">
          <svg className="w-8 h-8 text-[var(--primary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
        <p className="text-[var(--text-secondary)] mb-4">{error}</p>
        <button
          onClick={refresh}
          className="px-6 py-2.5 bg-[var(--primary)] text-white rounded-full font-medium btn-hover"
        >
          重试
        </button>
      </div>
    );
  }

  if (posts.length === 0 && !isLoading) {
    return (
      <div className="empty-state">
        <div className="w-20 h-20 mb-4 rounded-2xl bg-[var(--primary-light)] flex items-center justify-center">
          <span className="text-4xl">📭</span>
        </div>
        <p className="text-[var(--text-secondary)] mb-2">暂无内容</p>
        <p className="text-xs text-[var(--text-muted)] mb-4">稍后再来看看吧</p>
        <button
          onClick={refresh}
          className="px-6 py-2.5 bg-[var(--primary)] text-white rounded-full font-medium btn-hover"
        >
          刷新
        </button>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col">
      {/* 内容计数条 */}
      <div className="px-5 py-3 flex items-center justify-between bg-[var(--background)] border-b border-[var(--border)] flex-shrink-0">
        <span className="text-sm text-[var(--text-secondary)]">{posts.length} 条内容</span>
        <button
          onClick={refresh}
          className="text-xs text-[var(--primary)] font-medium hover:underline"
        >
          刷新
        </button>
      </div>

      {/* 帖子列表 - 可滚动区域 */}
      <div className="scroll-container-flex">
        <div className="divide-y divide-[var(--border)]">
          {posts.map((post, index) => (
            <div
              key={post.id}
              onClick={() => handlePostClick(post.id)}
              className="p-4 hover:bg-gray-50 transition-colors cursor-pointer active:bg-gray-100"
              style={{ animationDelay: `${index * 50}ms` }}
            >
              <PostCard post={post} onLoginRequired={() => {}} />
            </div>
          ))}
        </div>
      </div>

      {/* 加载更多 */}
      <div ref={loaderRef} className="p-8 text-center flex-shrink-0">
        {isLoading && (
          <div className="flex items-center justify-center gap-3">
            <div className="loading-spinner" />
            <span className="text-sm text-[var(--text-secondary)]">加载中...</span>
          </div>
        )}
        {!hasMore && posts.length > 0 && (
          <div className="flex items-center justify-center gap-2 text-[var(--text-muted)]">
            <span className="w-8 h-px bg-[var(--border)]"></span>
            <span className="text-xs">没有更多了</span>
            <span className="w-8 h-px bg-[var(--border)]"></span>
          </div>
        )}
      </div>
    </div>
  );
}