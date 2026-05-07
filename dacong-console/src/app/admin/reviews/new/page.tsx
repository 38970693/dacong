'use client';

/**
 * NewReviewPage - 新建评测文章
 */
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { MarkdownEditor } from '@/components/MarkdownEditor';

export default function NewReviewPage() {
  const router = useRouter();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [formData, setFormData] = useState<{
    title: string;
    slug: string;
    content: string;
    summary: string;
    author_name: string;
    author_avatar: string;
    cover_image: string;
    tags: string[];
    tools_mentioned: string[];
    published: boolean;
    published_at: string | null;
  }>({
    title: '',
    slug: '',
    content: '',
    summary: '',
    author_name: '匿名用户',
    author_avatar: '',
    cover_image: '',
    tags: [],
    tools_mentioned: [],
    published: false,
    published_at: null,
  });

  const [tagsInput, setTagsInput] = useState('');
  const [toolsInput, setToolsInput] = useState('');

  const handleSubmit = async (publishNow: boolean) => {
    // 验证
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

      const tools = toolsInput
        .split(/[,，]/)
        .map((t) => t.trim())
        .filter((t) => t.length > 0);

      const res = await fetch('/api/reviews', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...formData,
          tags,
          tools_mentioned: tools,
          published: publishNow,
        }),
      });

      const json = await res.json();

      if (json.success) {
        router.push('/admin/reviews');
      } else {
        setError(json.error || '创建失败');
      }
    } catch (err) {
      setError('网络错误');
    } finally {
      setIsSubmitting(false);
    }
  };

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
            <h1 className="text-2xl font-bold text-[var(--foreground)]">新建文章</h1>
            <p className="text-sm text-[var(--text-muted)]">创建新的评测文章</p>
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
              value={formData.title}
              onChange={(e) =>
                setFormData({ ...formData, title: e.target.value })
              }
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
              value={formData.summary}
              onChange={(e) =>
                setFormData({ ...formData, summary: e.target.value })
              }
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
              value={formData.content}
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
                  checked={formData.published}
                  onChange={(e) =>
                    setFormData({ ...formData, published: e.target.checked })
                  }
                  className="w-4 h-4 rounded border-[var(--border)] text-[var(--primary)] focus:ring-[var(--primary)]"
                />
                <span className="text-sm text-[var(--text-secondary)]">
                  立即发布
                </span>
              </label>

              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => handleSubmit(false)}
                  disabled={isSubmitting}
                  className="flex-1 py-2.5 bg-white border border-[var(--border)] text-[var(--foreground)] rounded-lg text-sm font-medium hover:bg-[var(--background)] transition-colors disabled:opacity-50"
                >
                  保存草稿
                </button>
                <button
                  type="button"
                  onClick={() => handleSubmit(true)}
                  disabled={isSubmitting}
                  className="flex-1 py-2.5 bg-[var(--primary)] text-white rounded-lg text-sm font-medium hover:bg-[var(--primary-dark)] transition-colors disabled:opacity-50"
                >
                  {isSubmitting ? '发布中...' : '发布'}
                </button>
              </div>
            </div>
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
                  value={formData.author_name}
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
                  value={formData.author_avatar}
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
                value={formData.cover_image}
                onChange={(e) =>
                  setFormData({ ...formData, cover_image: e.target.value })
                }
                placeholder="https://..."
                className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg text-sm text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
              />
              {formData.cover_image && (
                <div className="mt-2 rounded-lg overflow-hidden">
                  <img
                    src={formData.cover_image}
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
                value={formData.slug}
                onChange={(e) =>
                  setFormData({ ...formData, slug: e.target.value })
                }
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
