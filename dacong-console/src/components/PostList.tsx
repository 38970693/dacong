'use client';

import { useEffect, useRef, useCallback } from 'react';
import { usePostsStore } from '@/stores';
import { PostCard } from './PostCard';

export function PostList() {
  const { posts, isLoading, error, hasMore, fetchPosts, loadMore, refresh } = usePostsStore();
  const loaderRef = useRef<HTMLDivElement>(null);

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

  // 下拉刷新
  const handleRefresh = async () => {
    await refresh();
  };

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-full text-zinc-500">
        <p className="mb-4">{error}</p>
        <button
          onClick={refresh}
          className="px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 transition-colors"
        >
          重试
        </button>
      </div>
    );
  }

  if (posts.length === 0 && !isLoading) {
    return (
      <div className="flex flex-col items-center justify-center h-full text-zinc-500">
        <p className="mb-4">暂无内容</p>
        <button
          onClick={refresh}
          className="px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 transition-colors"
        >
          刷新
        </button>
      </div>
    );
  }

  return (
    <div className="h-full overflow-y-auto">
      {/* 下拉刷新提示 */}
      <div className="sticky top-0 z-10 bg-black/80 backdrop-blur-sm p-2 text-center text-xs text-zinc-500">
        下拉刷新 • {posts.length} 条内容
      </div>

      {/* 帖子列表 */}
      <div className="p-4">
        {posts.map((post) => (
          <PostCard key={post.id} post={post} />
        ))}
      </div>

      {/* 加载更多 */}
      <div ref={loaderRef} className="p-4 text-center">
        {isLoading && (
          <div className="flex items-center justify-center gap-2 text-zinc-500">
            <div className="w-4 h-4 border-2 border-orange-500 border-t-transparent rounded-full animate-spin" />
            <span>加载中...</span>
          </div>
        )}
        {!hasMore && posts.length > 0 && (
          <p className="text-zinc-600 text-sm">没有更多了</p>
        )}
      </div>
    </div>
  );
}