'use client';

import { useState } from 'react';
import { useAuthStore } from '@/stores';

interface LoginDialogProps {
  isOpen: boolean;
  onClose: () => void;
}

export function LoginDialog({ isOpen, onClose }: LoginDialogProps) {
  const [isSignUp, setIsSignUp] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const { signInWithEmail, signUp } = useAuthStore();

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // 验证
    if (!email || !password) {
      setError('请填写邮箱和密码');
      return;
    }

    if (!email.includes('@')) {
      setError('请输入有效的邮箱地址');
      return;
    }

    if (password.length < 6) {
      setError('密码至少需要 6 个字符');
      return;
    }

    if (isSignUp && password !== confirmPassword) {
      setError('两次输入的密码不一致');
      return;
    }

    setIsSubmitting(true);

    try {
      let result;
      if (isSignUp) {
        result = await signUp(email, password);
      } else {
        result = await signInWithEmail(email, password);
      }

      if (result.success) {
        // 登录成功，关闭对话框
        onClose();
        setEmail('');
        setPassword('');
        setConfirmPassword('');
      } else {
        setError(result.error || '操作失败');
      }
    } catch (err) {
      setError('操作失败，请稍后重试');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* 背景遮罩 */}
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* 对话框 */}
      <div className="relative w-full max-w-md mx-4 bg-white rounded-3xl shadow-2xl overflow-hidden">
        {/* 顶部渐变条 */}
        <div className="h-2 bg-gradient-to-r from-[var(--primary)] to-[var(--primary-light)]" />

        <div className="p-8">
          {/* 标题 */}
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold text-[var(--foreground)]">
              {isSignUp ? '注册账号' : '登录'}
            </h2>
            <button
              onClick={onClose}
              className="w-10 h-10 rounded-full bg-[var(--background)] flex items-center justify-center hover:bg-[var(--border)] transition-colors"
            >
              <svg className="w-5 h-5 text-[var(--text-secondary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          {/* 表单 */}
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* 邮箱 */}
            <div>
              <label className="block text-sm font-medium text-[var(--foreground)] mb-1.5">
                邮箱
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="请输入邮箱"
                className="w-full px-4 py-3 rounded-xl border border-[var(--border)] bg-[var(--background)] text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]/30 focus:border-[var(--primary)] transition-all"
              />
            </div>

            {/* 密码 */}
            <div>
              <label className="block text-sm font-medium text-[var(--foreground)] mb-1.5">
                密码
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="请输入密码"
                className="w-full px-4 py-3 rounded-xl border border-[var(--border)] bg-[var(--background)] text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]/30 focus:border-[var(--primary)] transition-all"
              />
            </div>

            {/* 确认密码（仅注册时显示） */}
            {isSignUp && (
              <div>
                <label className="block text-sm font-medium text-[var(--foreground)] mb-1.5">
                  确认密码
                </label>
                <input
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="请再次输入密码"
                  className="w-full px-4 py-3 rounded-xl border border-[var(--border)] bg-[var(--background)] text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:ring-2 focus:ring-[var(--primary)]/30 focus:border-[var(--primary)] transition-all"
                />
              </div>
            )}

            {/* 错误提示 */}
            {error && (
              <div className="p-3 bg-red-50 border border-red-200 rounded-xl">
                <p className="text-sm text-red-600">{error}</p>
              </div>
            )}

            {/* 提交按钮 */}
            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full py-3.5 bg-[var(--primary)] text-white rounded-full font-semibold btn-hover shadow-lg shadow-[var(--primary)]/20 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
            >
              {isSubmitting ? '处理中...' : (isSignUp ? '注册' : '登录')}
            </button>
          </form>

          {/* 切换登录/注册 */}
          <div className="mt-6 text-center">
            <span className="text-sm text-[var(--text-secondary)]">
              {isSignUp ? '已有账号？' : '还没有账号？'}
            </span>
            <button
              onClick={() => {
                setIsSignUp(!isSignUp);
                setError(null);
              }}
              className="ml-1 text-sm font-medium text-[var(--primary)] hover:underline"
            >
              {isSignUp ? '登录' : '注册'}
            </button>
          </div>

          {/* 提示 */}
          <div className="mt-6 text-xs text-center text-[var(--text-muted)]">
            登录即表示同意用户协议和隐私政策
          </div>
        </div>
      </div>
    </div>
  );
}