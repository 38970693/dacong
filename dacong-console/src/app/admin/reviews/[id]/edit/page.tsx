'use client';

/**
 * EditReviewPage - 编辑评测文章
 */
import { useState, useEffect } from 'react';
import { useRouter, useParams } from 'next/navigation';
import Link from 'next/link';
import { MarkdownEditor } from '@/components/MarkdownEditor';
import type { ReviewArticle, ReviewArticleUpdate } from '@/types/database';

interface ReviewResponse {
  success: boolean;
  data?: ReviewArticle;
  error?: string;
}

export default function EditReviewPage() {
  const router = useRouter();
  const params = useParams();
  const id = params.id as string;

  const [isLoading, setIsLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [formData, setFormData] = useState<ReviewArticleUpdate>({});
  const [tagsInput, setTagsInput] = useState('');
  const [toolsInput, setToolsInput] = useState('');
  const [originalData, setOriginalData] = useState<ReviewArticle | null>(null);

  // 加载文章数据
  useEffect(() => {
    async function loadReview() {
      if (!id) return;

      setIsLoading(true);
      try {
        const res = await fetch(`/api/reviews/${id}`);
        const json: ReviewResponse = await res.json();

        if (json.success && json.data) {
          setOriginalData(json.data);
          setFormData({
            title: json.data.title,
            slug: json.data.slug,
            content: json.data.content,
            summary: json.data.summary,
            author_name: json.data.author_name,
            author_avatar: json.data.author_avatar,
            cover_image: json.data.cover_image,
            tags: json.data.tags,
            tools_mentioned: json.data.tools_mentioned,
            published: json.data.published,
          });
          setTagsInput((json.data.tags || []).join(', '));
          setToolsInput((json.data.tools_mentioned || []).join(', '));
        } else {
          setError('文章不存在');
        }
      } catch (err) {
        setError('加载失败');
      } finally {
        setIsLoading(false);
      }
    }

    loadReview();
  }, [id]);

  const handleSubmit = async (publishNow?: boolean) => {
    if (!formData.title?.trim()) {
      setError('请输入标题');
      return;
    }
    if (!formData.summary?.trim()) {
      setError('请输入摘要');
      return;
    }
    if (!formData.content?.trim()) {
      setError('请输入文章内容');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      // 处理标签
      const tags = tagsInput
        .split(/[,，]/)
        .map((t) => t.trim())
        .filter((t) => t.length > 0);

      const tools_mentioned = toolsInput
        .split(/[,，]/)
        .map((t) => t.trim())
        .filter((t) => t.length > 0);

      const updateData: ReviewArticleUpdate = {
        ...formData,
        tags,
        tools_mentioned,
      };

      // 如果指定了 publishNow，覆盖当前设置
      if (publishNow !== undefined) {
        updateData.published = publishNow;
      }

      const res = await fetch(`/api/reviews/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updateData),
      });

      const json = await res.json();

      if (json.success) {
        router.push('/admin/reviews');
      } else {
        setError(json.error || '更新失败');
      }
    } catch (err) {
      setError('网络错误');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="w-8 h-8 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (error && !originalData) {
    return (
      <div className="text-center py-20">
        <p className="text-red-500 mb-4">{error}</p>
        <Link
          href="/admin/reviews"
          className="px-4 py-2 bg-[var(--primary)] text-white rounded-lg text-sm"
        >
          返回列表
        </Link>
      </div>
    );
  }

  return (
    <div>
      {/* 页面标题 */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-4">
          <Link
            href="/admin/reviews"
            className="w-10 h-10 rounded-lg bg-white border border-[var(--border)] flex items-center justify-center text-[var(--text-secondary)] hover:bg-[var(--background)] transition-colors"
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
            </svg>
          </Link>
          <div>
            <h1 className="text-2xl font-bold text-[var(--foreground)]">编辑文章</h1>
            <p className="text-sm text-[var(--text-muted)]">
              {originalData?.published ? '已发布' : '草稿'} · 最后更新于{' '}
              {originalData?.updated_at
                ? new Date(originalData.updated_at).toLocaleDateString('zh-CN')
                : '-'}
            </p>
          </div>
        </div>
      </div>

      {/* 错误提示 */}
      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-xl text-red-600 text-sm">
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* 主内容区 */}
        <div className="lg:col-span-2 space-y-6">
          {/* 标题 */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
              标题 <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              value={formData.title || ''}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              placeholder="输入文章标题"
              className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-lg text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
            />
          </div>

          {/* 摘要 */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
              摘要 <span className="text-red-500">*</span>
            </label>
            <textarea
              value={formData.summary || ''}
              onChange={(e) => setFormData({ ...formData, summary: e.target.value })}
              placeholder="简要描述文章内容..."
              rows={3}
              className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-lg text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)] resize-none"
            />
          </div>

          {/* Markdown 内容 */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
              文章内容 <span className="text-red-500">*</span>
            </label>
            <MarkdownEditor
              value={formData.content || ''}
              onChange={(value) => setFormData({ ...formData, content: value })}
              placeholder="使用 Markdown 编写文章内容..."
              minHeight={400}
            />
          </div>
        </div>

        {/* 侧边栏 */}
        <div className="space-y-6">
          {/* 发布设置 */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <h3 className="text-sm font-medium text-[var(--foreground)] mb-4">
              发布设置
            </h3>

            <div className="space-y-4">
              <label className="flex items-center gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={formData.published || false}
                  onChange={(e) =>
                    setFormData({ ...formData, published: e.target.checked })
                  }
                  className="w-4 h-4 rounded border-[var(--border)] text-[var(--primary)] focus:ring-[var(--primary)]"
                />
                <span className="text-sm text-[var(--text-secondary)]">
                  {formData.published ? '已发布' : '存为草稿'}
                </span>
              </label>

              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => handleSubmit(false)}
                  disabled={isSubmitting}
                  className="flex-1 py-2.5 bg-white border border-[var(--border)] text-[var(--foreground)] rounded-lg text-sm font-medium hover:bg-[var(--background)] transition-colors disabled:opacity-50"
                >
                  保存
                </button>
                <button
                  type="button"
                  onClick={() => handleSubmit(true)}
                  disabled={isSubmitting}
                  className="flex-1 py-2.5 bg-[var(--primary)] text-white rounded-lg text-sm font-medium hover:bg-[var(--primary-dark)] transition-colors disabled:opacity-50"
                >
                  {isSubmitting ? '保存中...' : '发布'}
                </button>
              </div>

              {formData.published && (
                <button
                  type="button"
                  onClick={() => {
                    if (confirm('确定要取消发布吗？')) {
                      handleSubmit(false);
                    }
                  }}
                  disabled={isSubmitting}
                  className="w-full py-2 text-sm text-red-500 hover:text-red-600 transition-colors disabled:opacity-50"
                >
                  取消发布
                </button>
              )}
            </div>
          </div>

          {/* 统计信息 */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <h3 className="text-sm font-medium text-[var(--foreground)] mb-4">
              数据统计
            </h3>

            <div className="grid grid-cols-2 gap-4">
              <div className="text-center p-3 bg-[var(--background)] rounded-lg">
                <div className="text-2xl font-bold text-[var(--foreground)]">
                  {originalData?.views || 0}
                </div>
                <div className="text-xs text-[var(--text-muted)]">浏览</div>
              </div>
              <div className="text-center p-3 bg-[var(--background)] rounded-lg">
                <div className="text-2xl font-bold text-[var(--foreground)]">
                  {originalData?.likes || 0}
                </div>
                <div className="text-xs text-[var(--text-muted)]">点赞</div>
              </div>
            </div>

            {formData.published && originalData?.slug && (
              <div className="mt-4 pt-4 border-t border-[var(--border)]">
                <Link
                  href={`/reviews/${originalData.slug}`}
                  target="_blank"
                  className="flex items-center justify-center gap-2 py-2 text-sm text-[var(--primary)] hover:underline"
                >
                  查看文章
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                  </svg>
                </Link>
              </div>
            )}
          </div>

          {/* 作者信息 */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <h3 className="text-sm font-medium text-[var(--foreground)] mb-4">
              作者信息
            </h3>

            <div className="space-y-4">
              <div>
                <label className="block text-xs text-[var(--text-muted)] mb-1.5">
                  作者名称
                </label>
                <input
                  type="text"
                  value={formData.author_name || ''}
                  onChange={(e) =>
                    setFormData({ ...formData, author_name: e.target.value })
                  }
                  placeholder="作者名称"
                  className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg text-sm text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
                />
              </div>

              <div>
                <label className="block text-xs text-[var(--text-muted)] mb-1.5">
                  头像 URL
                </label>
                <input
                  type="text"
                  value={formData.author_avatar || ''}
                  onChange={(e) =>
                    setFormData({ ...formData, author_avatar: e.target.value })
                  }
                  placeholder="https://..."
                  className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg text-sm text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
                />
              </div>
            </div>
          </div>

          {/* 封面图 */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <h3 className="text-sm font-medium text-[var(--foreground)] mb-4">
              封面图
            </h3>

            <div>
              <label className="block text-xs text-[var(--text-muted)] mb-1.5">
                封面图 URL
              </label>
              <input
                type="text"
                value={formData.cover_image || ''}
                onChange={(e) =>
                  setFormData({ ...formData, cover_image: e.target.value })
                }
                placeholder="https://..."
                className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg text-sm text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
              />
              {(formData.cover_image || originalData?.cover_image) && (
                <div className="mt-2 rounded-lg overflow-hidden">
                  <img
                    src={formData.cover_image || originalData?.cover_image || ''}
                    alt="封面预览"
                    className="w-full h-32 object-cover"
                    onError={(e) => {
                      (e.target as HTMLImageElement).style.display = 'none';
                    }}
                  />
                </div>
              )}
            </div>
          </div>

          {/* 标签 */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <h3 className="text-sm font-medium text-[var(--foreground)] mb-4">
              标签
            </h3>

            <div>
              <input
                type="text"
                value={tagsInput}
                onChange={(e) => setTagsInput(e.target.value)}
                placeholder="用逗号分隔，如：AI, 编程"
                className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg text-sm text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
              />
              <p className="mt-1.5 text-xs text-[var(--text-muted)]">
                用逗号分隔多个标签
              </p>
            </div>
          </div>

          {/* 提到的工具 */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <h3 className="text-sm font-medium text-[var(--foreground)] mb-4">
              提到的工具
            </h3>

            <div>
              <input
                type="text"
                value={toolsInput}
                onChange={(e) => setToolsInput(e.target.value)}
                placeholder="用逗号分隔，如：Claude, GPT-4"
                className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg text-sm text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
              />
              <p className="mt-1.5 text-xs text-[var(--text-muted)]">
                文章中提到的 AI 工具或服务
              </p>
            </div>
          </div>

          {/* SEO 设置 */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <h3 className="text-sm font-medium text-[var(--foreground)] mb-4">
              SEO 设置
            </h3>

            <div>
              <label className="block text-xs text-[var(--text-muted)] mb-1.5">
                URL Slug
              </label>
              <input
                type="text"
                value={formData.slug || ''}
                onChange={(e) => setFormData({ ...formData, slug: e.target.value })}
                placeholder="留空将自动生成"
                className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg text-sm text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
              />
              <p className="mt-1.5 text-xs text-[var(--text-muted)]">
                URL 友好的标识符，如：my-review-article
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
