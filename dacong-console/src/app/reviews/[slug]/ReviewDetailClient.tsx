'use client';

/**
 * ReviewDetailPage - 评测文章详情页（前台）
 */
import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import type { ReviewArticle } from '@/types/database';

interface ReviewResponse {
  success: boolean;
  data?: ReviewArticle;
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

// 简单的 Markdown 渲染（支持基本语法）
function renderMarkdown(content: string): string {
  if (!content) return '';

  let html = content
    // 标题
    .replace(/^### (.*$)/gim, '<h3 class="text-lg font-bold text-[var(--foreground)] mt-6 mb-3">$1</h3>')
    .replace(/^## (.*$)/gim, '<h2 class="text-xl font-bold text-[var(--foreground)] mt-8 mb-4">$1</h2>')
    .replace(/^# (.*$)/gim, '<h1 class="text-2xl font-bold text-[var(--foreground)] mt-8 mb-4">$1</h1>')
    // 粗体和斜体
    .replace(/\*\*\*(.*?)\*\*\*/g, '<strong><em>$1</em></strong>')
    .replace(/\*\*(.*?)\*\*/g, '<strong class="font-bold">$1</strong>')
    .replace(/\*(.*?)\*/g, '<em class="italic">$1</em>')
    // 代码块
    .replace(/```(\w*)\n([\s\S]*?)```/g, '<pre class="bg-[var(--background)] p-4 rounded-lg overflow-x-auto my-4"><code class="text-sm text-[var(--foreground)]">$2</code></pre>')
    // 行内代码
    .replace(/`([^`]+)`/g, '<code class="bg-[var(--background)] px-1.5 py-0.5 rounded text-sm text-[var(--primary)]">$1</code>')
    // 链接
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" class="text-[var(--primary)] hover:underline" target="_blank" rel="noopener">$1</a>')
    // 列表
    .replace(/^\- (.*$)/gim, '<li class="ml-4 mb-1 text-[var(--text-secondary)]">$1</li>')
    // 换行
    .replace(/\n\n/g, '</p><p class="text-[var(--text-secondary)] leading-relaxed mb-4">')
    .replace(/\n/g, '<br/>');

  // 包装段落
  html = '<p class="text-[var(--text-secondary)] leading-relaxed mb-4">' + html + '</p>';

  // 清理空段落
  html = html.replace(/<p class="text-\[var\(--text-secondary\)\] leading-relaxed mb-4"><\/p>/g, '');

  return html;
}

export default function ReviewDetailClient() {
  const params = useParams();
  const router = useRouter();
  const slug = params.slug as string;

  const [review, setReview] = useState<ReviewArticle | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchReview() {
      if (!slug) return;

      setIsLoading(true);
      setError(null);
      try {
        const res = await fetch(`/api/reviews/${slug}`);
        const json: ReviewResponse = await res.json();

        if (json.success && json.data) {
          setReview(json.data);
        } else {
          setError('文章不存在或已被删除');
        }
      } catch (err) {
        setError('加载失败');
      } finally {
        setIsLoading(false);
      }
    }

    fetchReview();
  }, [slug]);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-[var(--background)] flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (error || !review) {
    return (
      <div className="min-h-screen bg-[var(--background)] flex flex-col items-center justify-center gap-4">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-[var(--foreground)] mb-2">
            文章不存在
          </h1>
          <p className="text-[var(--text-muted)] mb-6">{error}</p>
        </div>
        <Link
          href="/reviews"
          className="px-6 py-3 bg-[var(--primary)] text-white rounded-full text-sm font-medium hover:bg-[var(--primary-dark)] transition-colors"
        >
          返回文章列表
        </Link>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[var(--background)]">
      {/* 顶部区域 */}
      <div className="bg-white border-b border-[var(--border)]">
        <div className="max-w-4xl mx-auto px-4 py-4">
          {/* 返回按钮 */}
          <Link
            href="/reviews"
            className="inline-flex items-center gap-2 text-sm text-[var(--text-secondary)] hover:text-[var(--foreground)] mb-4"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
            </svg>
            返回列表
          </Link>
        </div>
      </div>

      {/* 封面图 */}
      {review.cover_image && (
        <div className="w-full h-64 md:h-80 bg-[var(--background)]">
          <img
            src={review.cover_image}
            alt={review.title}
            className="w-full h-full object-cover"
          />
        </div>
      )}

      {/* 主内容 */}
      <main className="max-w-4xl mx-auto px-4 py-8 -mt-8">
        <article className="bg-white rounded-xl border border-[var(--border)] p-6 md:p-8">
          {/* 标签 */}
          {review.tags && review.tags.length > 0 && (
            <div className="flex flex-wrap gap-2 mb-4">
              {review.tags.map((tag) => (
                <Link
                  key={tag}
                  href={`/reviews?tag=${tag}`}
                  className="px-3 py-1 bg-[var(--background)] text-[var(--text-secondary)] text-sm rounded-full hover:bg-[var(--primary-light)] hover:text-[var(--primary)] transition-colors"
                >
                  #{tag}
                </Link>
              ))}
            </div>
          )}

          {/* 标题 */}
          <h1 className="text-2xl md:text-3xl font-bold text-[var(--foreground)] mb-6 leading-tight">
            {review.title}
          </h1>

          {/* 作者信息 */}
          <div className="flex items-center justify-between pb-6 mb-6 border-b border-[var(--border)]">
            <div className="flex items-center gap-3">
              {review.author_avatar ? (
                <img
                  src={review.author_avatar}
                  alt={review.author_name}
                  className="w-12 h-12 rounded-full"
                />
              ) : (
                <div className="w-12 h-12 rounded-full bg-[var(--primary)] text-white flex items-center justify-center text-lg font-bold">
                  {review.author_name?.charAt(0) || 'A'}
                </div>
              )}
              <div>
                <div className="font-medium text-[var(--foreground)]">
                  {review.author_name}
                </div>
                <div className="text-sm text-[var(--text-muted)]">
                  {review.published_at
                    ? formatDate(review.published_at)
                    : formatDate(review.created_at)}
                </div>
              </div>
            </div>

            {/* 统计数据 */}
            <div className="flex items-center gap-6 text-sm text-[var(--text-muted)]">
              <div className="flex items-center gap-1.5">
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path strokeLinecap="round" strokeLinejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
                <span>{review.views || 0}</span>
              </div>
              <div className="flex items-center gap-1.5">
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                </svg>
                <span>{review.likes || 0}</span>
              </div>
            </div>
          </div>

          {/* 摘要 */}
          {review.summary && (
            <div className="p-5 bg-[var(--background)] rounded-xl mb-6">
              <p className="text-[var(--text-secondary)] leading-relaxed">
                {review.summary}
              </p>
            </div>
          )}

          {/* 文章内容 */}
          <div
            className="prose prose-slate max-w-none"
            dangerouslySetInnerHTML={{ __html: renderMarkdown(review.content) }}
          />

          {/* 提到的工具 */}
          {review.tools_mentioned && review.tools_mentioned.length > 0 && (
            <div className="mt-8 pt-6 border-t border-[var(--border)]">
              <h3 className="text-sm font-medium text-[var(--foreground)] mb-3">
                本文涉及的工具
              </h3>
              <div className="flex flex-wrap gap-2">
                {review.tools_mentioned.map((tool) => (
                  <Link
                    key={tool}
                    href={`/?q=${tool}`}
                    className="px-3 py-1.5 bg-[var(--primary)]/10 text-[var(--primary)] text-sm rounded-full hover:bg-[var(--primary)]/20 transition-colors"
                  >
                    {tool}
                  </Link>
                ))}
              </div>
            </div>
          )}

          {/* 底部导航 */}
          <div className="mt-8 pt-6 border-t border-[var(--border)]">
            <Link
              href="/reviews"
              className="inline-flex items-center gap-2 text-sm text-[var(--primary)] hover:underline"
            >
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
              </svg>
              返回文章列表
            </Link>
          </div>
        </article>
      </main>
    </div>
  );
}