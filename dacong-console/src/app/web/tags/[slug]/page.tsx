'use client';

import { useParams, useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { PostCard } from '@/components/PostCard';

interface Tag {
  id: string;
  name: string;
  slug: string;
  color: string;
  post_count: number;
}

interface Post {
  id: string;
  title: string;
  content: string | null;
  source: string | null;
  source_url: string | null;
  views: number;
  likes: number;
  comments_count: number;
  created_at: string;
}

export default function TagPage() {
  const params = useParams();
  const router = useRouter();
  const slug = params?.slug as string;

  const [tag, setTag] = useState<Tag | null>(null);
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [loadingMore, setLoadingMore] = useState(false);

  useEffect(() => {
    if (slug) {
      fetchTagPosts();
    }
  }, [slug]);

  async function fetchTagPosts(pageNum = 1) {
    try {
      setError(null);
      const res = await fetch(`/api/tags/${slug}/posts?page=${pageNum}`);
      const json = await res.json();

      if (!json.success) {
        throw new Error(json.error || '获取标签文章失败');
      }

      setTag(json.data.tag);
      setTotal(json.data.total);

      if (pageNum === 1) {
        setPosts(json.data.posts);
      } else {
        setPosts(prev => [...prev, ...json.data.posts]);
      }
      setPage(pageNum);
    } catch (err) {
      console.error('Fetch tag posts error:', err);
      setError(err instanceof Error ? err.message : '加载失败');
      // 使用模拟数据降级
      setTag({
        id: '1',
        name: decodeURIComponent(slug),
        slug,
        color: '#3B82F6',
        post_count: 0
      });
      setPosts([]);
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  }

  function loadMore() {
    if (loadingMore || posts.length >= total) return;
    setLoadingMore(true);
    fetchTagPosts(page + 1);
  }

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh]">
        <div className="w-8 h-8 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin mb-4"></div>
        <p className="text-[var(--text-muted)]">加载中...</p>
      </div>
    );
  }

  return (
    <div>
      {/* 返回导航 */}
      <div className="sticky top-16 z-10 bg-[var(--background)]/95 backdrop-blur-sm px-5 py-4 border-b border-[var(--border)] flex items-center gap-4">
        <button
          className="w-10 h-10 rounded-full bg-white border border-[var(--border)] flex items-center justify-center hover:border-[var(--primary)] transition-colors"
          onClick={() => router.back()}
        >
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </button>
        <div className="flex-1">
          {tag && (
            <div className="flex items-center gap-3">
              <span
                className="inline-block w-4 h-4 rounded-full"
                style={{ backgroundColor: tag.color }}
              ></span>
              <h1 className="text-lg font-bold text-[var(--foreground)]">{tag.name}</h1>
              <span className="text-sm text-[var(--text-muted)]">{total} 篇文章</span>
            </div>
          )}
        </div>
      </div>

      {/* 错误状态 */}
      {error && (
        <div className="mx-5 mt-5 p-4 bg-red-50 border border-red-200 rounded-xl text-red-700">
          {error}
        </div>
      )}

      {/* 文章列表 */}
      <div className="p-5">
        {posts.length === 0 ? (
          <div className="text-center py-12">
            <div className="text-4xl mb-4">🏷️</div>
            <p className="text-[var(--text-muted)]">暂无文章</p>
            <p className="text-sm text-[var(--text-muted)] mt-2">
              标签 "{tag?.name}" 下还没有文章
            </p>
          </div>
        ) : (
          <>
            <div className="space-y-4">
              {posts.map((post) => (
                <PostCard key={post.id} post={post} />
              ))}
            </div>

            {/* 加载更多 */}
            {posts.length < total && (
              <div className="mt-6 text-center">
                <button
                  onClick={loadMore}
                  disabled={loadingMore}
                  className="px-6 py-2.5 bg-white border border-[var(--border)] text-[var(--foreground)] rounded-full hover:border-[var(--primary)] hover:text-[var(--primary)] transition-colors disabled:opacity-50"
                >
                  {loadingMore ? '加载中...' : `加载更多 (${posts.length}/${total})`}
                </button>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}