'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useReviewsStore } from '@/stores';
import Link from 'next/link';

interface Model {
  id: string;
  name: string;
  provider: string;
}

const reviewTypes = ['深度评测', '对比测试', '专项测试', '用户评测'];

export default function NewReviewPage() {
  const router = useRouter();
  const { createReview, isLoading, error } = useReviewsStore();

  const [models, setModels] = useState<Model[]>([]);
  const [formData, setFormData] = useState({
    title: '',
    model_id: '',
    model_name: '',
    review_type: '深度评测' as const,
    rating: 5,
    summary: '',
    content: '',
    tags: '',
  });
  const [submitError, setSubmitError] = useState<string | null>(null);

  // 加载模型列表
  useEffect(() => {
    async function loadModels() {
      try {
        const res = await fetch('/api/models');
        const json = await res.json();
        if (json.success) {
          setModels(json.data);
        }
      } catch (err) {
        console.error('加载模型失败:', err);
      }
    }
    loadModels();
  }, []);

  const handleModelChange = (modelId: string) => {
    const model = models.find(m => m.id === modelId);
    setFormData(prev => ({
      ...prev,
      model_id: modelId,
      model_name: model?.name || '',
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitError(null);

    // 验证
    if (!formData.title.trim()) {
      setSubmitError('请输入标题');
      return;
    }
    if (!formData.model_id) {
      setSubmitError('请选择评测模型');
      return;
    }
    if (!formData.summary.trim()) {
      setSubmitError('请输入摘要');
      return;
    }
    if (!formData.content.trim()) {
      setSubmitError('请输入评测内容');
      return;
    }

    try {
      const tags = formData.tags
        .split(/[,，]/)
        .map(t => t.trim())
        .filter(t => t.length > 0);

      const newReview = await createReview({
        model_id: formData.model_id,
        model_name: formData.model_name,
        title: formData.title,
        summary: formData.summary,
        content: formData.content,
        reviewer: '匿名用户',
        rating: formData.rating,
        review_type: formData.review_type,
        tags,
        is_featured: false,
      });

      if (newReview) {
        router.push(`/web/review/${newReview.id}`);
      }
    } catch (err) {
      setSubmitError('发布失败，请重试');
    }
  };

  return (
    <div className="pb-16 md:pb-0">
      {/* 页面标题 */}
      <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        <div className="flex items-center gap-3">
          <Link
            href="/web/review"
            className="w-8 h-8 rounded-full bg-[var(--background)] flex items-center justify-center text-[var(--text-secondary)] hover:bg-[var(--primary-light)] hover:text-[var(--primary)] transition-all"
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
            </svg>
          </Link>
          <h1 className="text-lg font-bold text-[var(--foreground)]">写评测</h1>
        </div>
      </div>

      {/* 表单 */}
      <form onSubmit={handleSubmit} className="p-4 md:p-5 space-y-5">
        {/* 错误提示 */}
        {(submitError || error) && (
          <div className="p-3 bg-red-50 border border-red-200 rounded-xl text-red-600 text-sm">
            {submitError || error}
          </div>
        )}

        {/* 标题 */}
        <div>
          <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
            标题 <span className="text-red-500">*</span>
          </label>
          <input
            type="text"
            value={formData.title}
            onChange={e => setFormData(prev => ({ ...prev, title: e.target.value }))}
            placeholder="给评测起个吸引人的标题"
            className="w-full px-4 py-3 bg-white border border-[var(--border)] rounded-xl text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
          />
        </div>

        {/* 模型选择 */}
        <div>
          <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
            评测模型 <span className="text-red-500">*</span>
          </label>
          <select
            value={formData.model_id}
            onChange={e => handleModelChange(e.target.value)}
            className="w-full px-4 py-3 bg-white border border-[var(--border)] rounded-xl text-[var(--foreground)] focus:outline-none focus:border-[var(--primary)]"
          >
            <option value="">选择要评测的模型</option>
            {models.map(model => (
              <option key={model.id} value={model.id}>
                {model.name} - {model.provider}
              </option>
            ))}
          </select>
        </div>

        {/* 评测类型 */}
        <div>
          <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
            评测类型
          </label>
          <div className="flex flex-wrap gap-2">
            {reviewTypes.map(type => (
              <button
                key={type}
                type="button"
                onClick={() => setFormData(prev => ({ ...prev, review_type: type as typeof prev.review_type }))}
                className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${
                  formData.review_type === type
                    ? 'bg-[var(--primary)] text-white'
                    : 'bg-white border border-[var(--border)] text-[var(--text-secondary)] hover:border-[var(--primary)]'
                }`}
              >
                {type}
              </button>
            ))}
          </div>
        </div>

        {/* 评分 */}
        <div>
          <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
            评分
          </label>
          <div className="flex items-center gap-2">
            {[1, 2, 3, 4, 5].map(star => (
              <button
                key={star}
                type="button"
                onClick={() => setFormData(prev => ({ ...prev, rating: star }))}
                className="text-2xl transition-transform hover:scale-110"
              >
                <span className={star <= formData.rating ? 'text-amber-400' : 'text-gray-300'}>
                  ★
                </span>
              </button>
            ))}
            <span className="ml-2 text-sm text-[var(--text-secondary)]">
              {formData.rating} / 5
            </span>
          </div>
        </div>

        {/* 标签 */}
        <div>
          <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
            标签
          </label>
          <input
            type="text"
            value={formData.tags}
            onChange={e => setFormData(prev => ({ ...prev, tags: e.target.value }))}
            placeholder="用逗号分隔，如：编程,创意写作,中文"
            className="w-full px-4 py-3 bg-white border border-[var(--border)] rounded-xl text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
          />
          <p className="mt-1 text-xs text-[var(--text-muted)]">用逗号分隔多个标签</p>
        </div>

        {/* 摘要 */}
        <div>
          <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
            摘要 <span className="text-red-500">*</span>
          </label>
          <textarea
            value={formData.summary}
            onChange={e => setFormData(prev => ({ ...prev, summary: e.target.value }))}
            placeholder="简要描述评测的核心内容和结论"
            rows={3}
            className="w-full px-4 py-3 bg-white border border-[var(--border)] rounded-xl text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)] resize-none"
          />
        </div>

        {/* 内容 */}
        <div>
          <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
            评测内容 <span className="text-red-500">*</span>
          </label>
          <textarea
            value={formData.content}
            onChange={e => setFormData(prev => ({ ...prev, content: e.target.value }))}
            placeholder="详细描述你的评测体验，包括优点、缺点、适用场景等..."
            rows={10}
            className="w-full px-4 py-3 bg-white border border-[var(--border)] rounded-xl text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)] resize-none"
          />
        </div>

        {/* 提交按钮 */}
        <div className="pt-4">
          <button
            type="submit"
            disabled={isLoading}
            className="w-full py-3 bg-[var(--primary)] text-white rounded-xl font-semibold hover:bg-[var(--primary-dark)] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isLoading ? (
              <span className="flex items-center justify-center gap-2">
                <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                发布中...
              </span>
            ) : (
              '发布评测'
            )}
          </button>
        </div>
      </form>
    </div>
  );
}