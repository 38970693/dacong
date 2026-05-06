'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuthStore, useFavoritesStore, usePostsStore } from '@/stores';
import { EmptyState } from '@/components/ui/EmptyState';
import type { Post } from '@/types/database';

interface SavedItem {
  id: string;
  target_type: 'post' | 'review' | 'model';
  target_id: string;
  created_at: string;
  post?: Post;
}

export default function SavedPage() {
  const router = useRouter();
  const { user, isInitialized } = useAuthStore();
  const { favorites, isLoading: favLoading, loadFavorites, removeFavorite } = useFavoritesStore();
  const { posts } = usePostsStore();
  const [savedPosts, setSavedPosts] = useState<SavedItem[]>([]);
  const [loading, setLoading] = useState(true);

  // 加载收藏的帖子
  useEffect(() => {
    if (isInitialized && user) {
      loadFavorites(user.id);
    }
  }, [isInitialized, user, loadFavorites]);

  // 根据收藏获取帖子详情
  useEffect(() => {
    async function fetchSavedPosts() {
      if (!user || favorites.length === 0) {
        setSavedPosts([]);
        setLoading(false);
        return;
      }

      setLoading(true);

      // 获取收藏的帖子
      const postFavorites = favorites.filter(f => f.target_type === 'post');
      if (postFavorites.length === 0) {
        setSavedPosts([]);
        setLoading(false);
        return;
      }

      const savedPostIds = postFavorites.map(f => f.target_id);

      // 从 postsStore 中获取帖子详情，或者从 API 获取
      const foundPosts = posts.filter(p => savedPostIds.includes(p.id));
      const missingIds = savedPostIds.filter(id => !foundPosts.some(p => p.id === id));

      // 如果有缺失的，从 API 获取
      if (missingIds.length > 0) {
        try {
          const res = await fetch('/api/posts?ids=' + missingIds.join(','));
          const json = await res.json();
          if (json.success) {
            foundPosts.push(...json.data);
          }
        } catch (err) {
          console.error('获取收藏帖子失败:', err);
        }
      }

      // 合并收藏和帖子信息
      const savedItems: SavedItem[] = postFavorites.map(fav => ({
        ...fav,
        post: foundPosts.find(p => p.id === fav.target_id),
      }));

      setSavedPosts(savedItems);
      setLoading(false);
    }

    fetchSavedPosts();
  }, [favorites, user, posts]);

  // 移除收藏
  const handleUnsave = async (targetId: string) => {
    if (!user) return;
    const success = await removeFavorite(user.id, 'post', targetId);
    if (success) {
      setSavedPosts(prev => prev.filter(item => item.target_id !== targetId));
    }
  };

  // 未登录状态
  if (!isInitialized) {
    return (
      <div className="pb-16 md:pb-0">
        <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
          <h1 className="text-lg font-bold text-[var(--foreground)] flex items-center gap-2">
            <span>🔖</span>
            <span>我的收藏</span>
          </h1>
        </div>
        <div className="p-8 flex items-center justify-center">
          <div className="w-8 h-8 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin"></div>
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="pb-16 md:pb-0">
        <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
          <h1 className="text-lg font-bold text-[var(--foreground)] flex items-center gap-2">
            <span>🔖</span>
            <span>我的收藏</span>
          </h1>
        </div>
        <div className="p-6 md:p-8 text-center">
          <div className="w-20 h-20 mx-auto mb-4 rounded-2xl bg-[var(--primary-light)] flex items-center justify-center">
            <span className="text-4xl">🔐</span>
          </div>
          <p className="text-[var(--text-secondary)] mb-2">登录后查看收藏内容</p>
          <p className="text-xs text-[var(--text-muted)] mb-6">收藏你感兴趣的内容，随时查看</p>
          <button
            onClick={() => router.push('/web/auth/login')}
            className="px-6 md:px-8 py-2.5 bg-[var(--primary)] text-white rounded-full font-semibold btn-hover"
          >
            登录
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="pb-16 md:pb-0">
      {/* 页面标题 */}
      <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        <h1 className="text-lg font-bold text-[var(--foreground)] flex items-center gap-2">
          <span>🔖</span>
          <span>我的收藏</span>
        </h1>
        <p className="text-xs text-[var(--text-muted)] hidden md:block">已收藏 {savedPosts.length} 篇文章</p>
      </div>

      {/* 加载状态 */}
      {loading || favLoading ? (
        <div className="p-8 flex items-center justify-center">
          <div className="w-8 h-8 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin"></div>
        </div>
      ) : savedPosts.length === 0 ? (
        /* 空状态 */
        <EmptyState
          title="暂无收藏"
          description="去首页发现感兴趣的内容吧"
          icon="bookmark"
          action={{
            label: '去首页探索',
            onClick: () => router.push('/web')
          }}
        />
      ) : (
        /* 收藏列表 */
        <div className="divide-y divide-[var(--border)]">
          {savedPosts.map((item) => (
            <div key={item.id} className="relative group">
              <Link
                href={`/web/post/${item.target_id}`}
                className="block p-4 md:p-5 hover:bg-[var(--background)] transition-colors"
              >
                <h3 className="font-medium text-[var(--foreground)] mb-2 line-clamp-2">
                  {item.post?.title || '加载中...'}
                </h3>
                <div className="flex items-center gap-3 text-xs text-[var(--text-muted)]">
                  <span>{item.post?.source || '未知来源'}</span>
                  <span>•</span>
                  <span>
                    收藏于{' '}
                    {new Date(item.created_at).toLocaleDateString('zh-CN', {
                      month: 'short',
                      day: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </span>
                </div>
              </Link>

              {/* 取消收藏按钮 */}
              <button
                onClick={() => handleUnsave(item.target_id)}
                className="absolute top-4 right-4 w-8 h-8 rounded-full bg-[var(--background)] flex items-center justify-center text-[var(--text-muted)] hover:bg-red-50 hover:text-red-500 transition-colors opacity-0 group-hover:opacity-100"
                title="取消收藏"
              >
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}