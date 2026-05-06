'use client';

import { useState, useEffect } from 'react';
import { useAuthStore } from '@/stores';

interface FeedbackModalProps {
  isOpen: boolean;
  onClose: () => void;
}

type FeedbackType = 'suggestion' | 'bug' | 'business' | 'other';
type FeedbackStatus = 'idle' | 'submitting' | 'success' | 'error';

interface FeedbackTypeOption {
  id: FeedbackType;
  label: string;
  icon: string;
  description: string;
}

const feedbackTypes: FeedbackTypeOption[] = [
  {
    id: 'suggestion',
    label: '功能建议',
    icon: '💡',
    description: '对产品功能的改进建议',
  },
  {
    id: 'bug',
    label: '问题反馈',
    icon: '🐛',
    description: '报告遇到的 Bug 或问题',
  },
  {
    id: 'business',
    label: '商务合作',
    icon: '🤝',
    description: '商务洽谈、媒体合作',
  },
  {
    id: 'other',
    label: '其他咨询',
    icon: '💬',
    description: '其他问题或想说的话',
  },
];

export function FeedbackModal({ isOpen, onClose }: FeedbackModalProps) {
  const { user } = useAuthStore();
  const [selectedType, setSelectedType] = useState<FeedbackType>('suggestion');
  const [content, setContent] = useState('');
  const [contact, setContact] = useState('');
  const [status, setStatus] = useState<FeedbackStatus>('idle');
  const [errorMessage, setErrorMessage] = useState('');

  // 关闭时重置表单
  useEffect(() => {
    if (!isOpen) {
      setSelectedType('suggestion');
      setContent('');
      setContact('');
      setStatus('idle');
      setErrorMessage('');
    }
  }, [isOpen]);

  // ESC 键关闭
  useEffect(() => {
    const handleEsc = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    if (isOpen) {
      window.addEventListener('keydown', handleEsc);
      return () => window.removeEventListener('keydown', handleEsc);
    }
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const handleSubmit = async () => {
    if (!content.trim()) {
      setErrorMessage('请输入反馈内容');
      return;
    }

    setStatus('submitting');
    setErrorMessage('');

    try {
      // 尝试发送到 API
      const response = await fetch('/api/feedback', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          type: selectedType,
          content: content.trim(),
          contact: contact.trim() || null,
          user_id: user?.id || null,
          user_email: user?.email || null,
        }),
      });

      if (response.ok) {
        setStatus('success');
      } else {
        throw new Error('提交失败');
      }
    } catch {
      // 如果 API 失败，使用 mailto 作为后备方案
      const typeLabel = feedbackTypes.find(t => t.id === selectedType)?.label || '其他';
      const subject = encodeURIComponent(`[DaCong Feedback] ${typeLabel}`);
      const body = encodeURIComponent(
        `反馈类型：${typeLabel}\n\n${content}\n\n联系方式：${contact || '未填写'}`
      );
      window.location.href = `mailto:dacong@example.com?subject=${subject}&body=${body}`;
      setStatus('success');
    }
  };

  // 成功状态
  if (status === 'success') {
    return (
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div className="absolute inset-0 bg-black/50" onClick={onClose} />
        <div className="relative bg-white rounded-2xl w-full max-w-md p-8 text-center">
          <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-green-100 flex items-center justify-center">
            <span className="text-3xl">✨</span>
          </div>
          <h3 className="text-xl font-bold text-[var(--foreground)] mb-2">感谢您的反馈</h3>
          <p className="text-sm text-[var(--text-secondary)] mb-6">
            我们已收到您的反馈，会认真考虑并尽快处理
          </p>
          <button
            onClick={onClose}
            className="px-6 py-2.5 bg-[var(--primary)] text-white rounded-full font-semibold"
          >
            知道了
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* 遮罩 */}
      <div className="absolute inset-0 bg-black/50" onClick={onClose} />

      {/* 模态框 */}
      <div className="relative bg-white rounded-2xl w-full max-w-md max-h-[90vh] overflow-hidden flex flex-col">
        {/* 标题栏 */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-[var(--border)]">
          <h3 className="text-lg font-bold text-[var(--foreground)]">帮助与反馈</h3>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-[var(--background)] flex items-center justify-center text-[var(--text-muted)] hover:bg-[var(--border)] transition-colors"
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* 内容区 */}
        <div className="flex-1 overflow-y-auto p-5 space-y-5">
          {/* 反馈类型选择 */}
          <div>
            <label className="block text-sm font-medium text-[var(--foreground)] mb-3">
              反馈类型
            </label>
            <div className="grid grid-cols-2 gap-2">
              {feedbackTypes.map((type) => (
                <button
                  key={type.id}
                  onClick={() => setSelectedType(type.id)}
                  className={`p-3 rounded-xl border text-left transition-all ${
                    selectedType === type.id
                      ? 'border-[var(--primary)] bg-[var(--primary-light)]/30'
                      : 'border-[var(--border)] hover:border-[var(--primary)]/50'
                  }`}
                >
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-lg">{type.icon}</span>
                    <span className="text-sm font-medium text-[var(--foreground)]">{type.label}</span>
                  </div>
                  <p className="text-xs text-[var(--text-muted)] line-clamp-1">{type.description}</p>
                </button>
              ))}
            </div>
          </div>

          {/* 反馈内容 */}
          <div>
            <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
              反馈内容 <span className="text-red-500">*</span>
            </label>
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder="请详细描述您的问题或建议..."
              rows={5}
              className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl text-[var(--foreground)] placeholder:text-[var(--text-muted)] resize-none focus:outline-none focus:border-[var(--primary)]"
            />
          </div>

          {/* 联系方式 */}
          <div>
            <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
              联系方式 <span className="text-[var(--text-muted)] font-normal">(选填)</span>
            </label>
            <input
              type="text"
              value={contact}
              onChange={(e) => setContact(e.target.value)}
              placeholder="邮箱、微信号或手机号"
              className="w-full px-4 py-3 bg-[var(--background)] border border-[var(--border)] rounded-xl text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
            />
            <p className="text-xs text-[var(--text-muted)] mt-2">
              留下联系方式，方便我们更快地回复您
            </p>
          </div>

          {/* 错误提示 */}
          {errorMessage && (
            <div className="p-3 bg-red-50 border border-red-200 rounded-xl text-red-600 text-sm">
              {errorMessage}
            </div>
          )}
        </div>

        {/* 底部按钮 */}
        <div className="px-5 py-4 border-t border-[var(--border)]">
          <button
            onClick={handleSubmit}
            disabled={status === 'submitting'}
            className="w-full py-3 bg-[var(--primary)] text-white rounded-xl font-semibold hover:bg-[var(--primary-dark)] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {status === 'submitting' ? (
              <span className="flex items-center justify-center gap-2">
                <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                提交中...
              </span>
            ) : (
              '提交反馈'
            )}
          </button>
        </div>
      </div>
    </div>
  );
}