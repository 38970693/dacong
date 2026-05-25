'use client';

/**
 * EditReviewClient - 编辑评测文章（客户端组件）
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

export default function EditReviewClient() {
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

  // Load article data
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
          setError('Article not found');
        }
      } catch (err) {
        setError('Failed to load');
      } finally {
        setIsLoading(false);
      }
    }

    loadReview();
  }, [id]);

  const handleSubmit = async (publishNow?: boolean) => {
    if (!formData.title?.trim()) {
      setError('Please enter a title');
      return;
    }
    if (!formData.summary?.trim()) {
      setError('Please enter a summary');
      return;
    }
    if (!formData.content?.trim()) {
      setError('Please enter content');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      // Process tags
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

      // Override with publishNow if specified
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
        setError(json.error || 'Update failed');
      }
    } catch (err) {
      setError('Network error');
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
          Back to List
        </Link>
      </div>
    );
  }

  return (
    <div>
      {/* Page header */}
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
            <h1 className="text-2xl font-bold text-[var(--foreground)]">Edit Article</h1>
            <p className="text-sm text-[var(--text-muted)]">
              {originalData?.published ? 'Published' : 'Draft'} · Last updated{' '}
              {originalData?.updated_at
                ? new Date(originalData.updated_at).toLocaleDateString('en-US')
                : '-'}
            </p>
          </div>
        </div>
      </div>

      {/* Error message */}
      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-xl text-red-600 text-sm">
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main content */}
        <div className="lg:col-span-2 space-y-6">
          {/* Title */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Title <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              value={formData.title || ''}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              placeholder="Enter article title"
              className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-lg text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
            />
          </div>

          {/* Summary */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Summary <span className="text-red-500">*</span>
            </label>
            <textarea
              value={formData.summary || ''}
              onChange={(e) => setFormData({ ...formData, summary: e.target.value })}
              placeholder="Brief description of the article..."
              rows={3}
              className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-lg text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)] resize-none"
            />
          </div>

          {/* Markdown content */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
              Content <span className="text-red-500">*</span>
            </label>
            <MarkdownEditor
              value={formData.content || ''}
              onChange={(value) => setFormData({ ...formData, content: value })}
              placeholder="Write article content using Markdown..."
              minHeight={400}
            />
          </div>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Publish settings */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <h3 className="text-sm font-medium text-[var(--foreground)] mb-4">
              Publish Settings
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
                  {formData.published ? 'Published' : 'Save as draft'}
                </span>
              </label>

              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => handleSubmit(false)}
                  disabled={isSubmitting}
                  className="flex-1 py-2.5 bg-white border border-[var(--border)] text-[var(--foreground)] rounded-lg text-sm font-medium hover:bg-[var(--background)] transition-colors disabled:opacity-50"
                >
                  Save
                </button>
                <button
                  type="button"
                  onClick={() => handleSubmit(true)}
                  disabled={isSubmitting}
                  className="flex-1 py-2.5 bg-[var(--primary)] text-white rounded-lg text-sm font-medium hover:bg-[var(--primary-dark)] transition-colors disabled:opacity-50"
                >
                  {isSubmitting ? 'Saving...' : 'Publish'}
                </button>
              </div>

              {formData.published && (
                <button
                  type="button"
                  onClick={() => {
                    if (confirm('Unpublish this article?')) {
                      handleSubmit(false);
                    }
                  }}
                  disabled={isSubmitting}
                  className="w-full py-2 text-sm text-red-500 hover:text-red-600 transition-colors disabled:opacity-50"
                >
                  Unpublish
                </button>
              )}
            </div>
          </div>

          {/* Statistics */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <h3 className="text-sm font-medium text-[var(--foreground)] mb-4">
              Statistics
            </h3>

            <div className="grid grid-cols-2 gap-4">
              <div className="text-center p-3 bg-[var(--background)] rounded-lg">
                <div className="text-2xl font-bold text-[var(--foreground)]">
                  {originalData?.views || 0}
                </div>
                <div className="text-xs text-[var(--text-muted)]">Views</div>
              </div>
              <div className="text-center p-3 bg-[var(--background)] rounded-lg">
                <div className="text-2xl font-bold text-[var(--foreground)]">
                  {originalData?.likes || 0}
                </div>
                <div className="text-xs text-[var(--text-muted)]">Likes</div>
              </div>
            </div>

            {formData.published && originalData?.slug && (
              <div className="mt-4 pt-4 border-t border-[var(--border)]">
                <Link
                  href={`/reviews/${originalData.slug}`}
                  target="_blank"
                  className="flex items-center justify-center gap-2 py-2 text-sm text-[var(--primary)] hover:underline"
                >
                  View Article
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                  </svg>
                </Link>
              </div>
            )}
          </div>

          {/* Author info */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <h3 className="text-sm font-medium text-[var(--foreground)] mb-4">
              Author Info
            </h3>

            <div className="space-y-4">
              <div>
                <label className="block text-xs text-[var(--text-muted)] mb-1.5">
                  Author Name
                </label>
                <input
                  type="text"
                  value={formData.author_name || ''}
                  onChange={(e) =>
                    setFormData({ ...formData, author_name: e.target.value })
                  }
                  placeholder="Author name"
                  className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg text-sm text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
                />
              </div>

              <div>
                <label className="block text-xs text-[var(--text-muted)] mb-1.5">
                  Avatar URL
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

          {/* Cover image */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <h3 className="text-sm font-medium text-[var(--foreground)] mb-4">
              Cover Image
            </h3>

            <div>
              <label className="block text-xs text-[var(--text-muted)] mb-1.5">
                Cover Image URL
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
                    alt="Cover preview"
                    className="w-full h-32 object-cover"
                    onError={(e) => {
                      (e.target as HTMLImageElement).style.display = 'none';
                    }}
                  />
                </div>
              )}
            </div>
          </div>

          {/* Tags */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <h3 className="text-sm font-medium text-[var(--foreground)] mb-4">
              Tags
            </h3>

            <div>
              <input
                type="text"
                value={tagsInput}
                onChange={(e) => setTagsInput(e.target.value)}
                placeholder="Separate with commas, e.g.: AI, Coding"
                className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg text-sm text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
              />
              <p className="mt-1.5 text-xs text-[var(--text-muted)]">
                Separate multiple tags with commas
              </p>
            </div>
          </div>

          {/* Tools mentioned */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <h3 className="text-sm font-medium text-[var(--foreground)] mb-4">
              Tools Mentioned
            </h3>

            <div>
              <input
                type="text"
                value={toolsInput}
                onChange={(e) => setToolsInput(e.target.value)}
                placeholder="Separate with commas, e.g.: Claude, GPT-4"
                className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg text-sm text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
              />
              <p className="mt-1.5 text-xs text-[var(--text-muted)]">
                AI tools or services mentioned in the article
              </p>
            </div>
          </div>

          {/* SEO settings */}
          <div className="bg-white rounded-xl border border-[var(--border)] p-4">
            <h3 className="text-sm font-medium text-[var(--foreground)] mb-4">
              SEO Settings
            </h3>

            <div>
              <label className="block text-xs text-[var(--text-muted)] mb-1.5">
                URL Slug
              </label>
              <input
                type="text"
                value={formData.slug || ''}
                onChange={(e) => setFormData({ ...formData, slug: e.target.value })}
                placeholder="Leave empty for auto-generated"
                className="w-full px-3 py-2 bg-[var(--background)] border border-[var(--border)] rounded-lg text-sm text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
              />
              <p className="mt-1.5 text-xs text-[var(--text-muted)]">
                URL-friendly identifier, e.g.: my-review-article
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}