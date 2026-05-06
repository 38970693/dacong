'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/stores';

export default function RegisterPage() {
  const router = useRouter();
  const { user, signUp, signInWithOAuth, isLoading, initialize, error, clearError } = useAuthStore();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [localError, setLocalError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  // 初始化认证状态
  useEffect(() => {
    initialize();
  }, [initialize]);

  // 如果已登录，跳转首页
  useEffect(() => {
    if (user) {
      router.push('/web');
    }
  }, [user, router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLocalError(null);
    clearError();

    if (!email.trim()) {
      setLocalError('请输入邮箱');
      return;
    }
    if (!password) {
      setLocalError('请输入密码');
      return;
    }
    if (password.length < 6) {
      setLocalError('密码至少需要 6 个字符');
      return;
    }
    if (password !== confirmPassword) {
      setLocalError('两次输入的密码不一致');
      return;
    }

    const result = await signUp(email, password);
    if (result.success) {
      setSuccess(true);
    } else {
      setLocalError(result.error || '注册失败');
    }
  };

  // 注册成功页面
  if (success) {
    return (
      <div className="min-h-screen bg-[var(--background)] flex flex-col">
        <div className="flex-1 flex flex-col justify-center items-center p-5">
          <div className="max-w-sm mx-auto w-full text-center">
            <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-green-100 flex items-center justify-center">
              <span className="text-3xl">📧</span>
            </div>
            <h2 className="text-2xl font-bold text-[var(--foreground)] mb-2">验证邮件已发送</h2>
            <p className="text-[var(--text-secondary)] mb-6">
              我们已向 <span className="font-medium">{email}</span> 发送了一封验证邮件，
              请点击邮件中的链接完成注册。
            </p>
            <p className="text-xs text-[var(--text-muted)] mb-6">
              如果没有收到邮件，请检查垃圾邮件文件夹。
            </p>
            <Link
              href="/web/auth/login"
              className="inline-block px-6 py-2.5 bg-[var(--primary)] text-white rounded-full font-semibold"
            >
              返回登录
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[var(--background)] flex flex-col">
      {/* 顶部导航 */}
      <div className="sticky top-0 z-10 bg-white/95 backdrop-blur-sm px-4 py-4 border-b border-[var(--border)]">
        <div className="max-w-lg mx-auto flex items-center justify-between">
          <Link
            href="/web"
            className="w-10 h-10 rounded-full bg-[var(--background)] flex items-center justify-center text-[var(--text-secondary)]"
          >
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
            </svg>
          </Link>
          <h1 className="text-lg font-bold text-[var(--foreground)]">注册</h1>
          <div className="w-10" />
        </div>
      </div>

      {/* 表单 */}
      <div className="flex-1 flex flex-col justify-center p-5">
        <div className="max-w-sm mx-auto w-full">
          {/* Logo */}
          <div className="text-center mb-8">
            <div className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-[var(--gradient-amber)] to-[var(--gradient-pink)] flex items-center justify-center">
              <span className="text-white font-bold text-2xl">AI</span>
            </div>
            <h2 className="text-2xl font-bold text-[var(--foreground)]">创建账号</h2>
            <p className="text-sm text-[var(--text-secondary)] mt-2">加入 DaCong，探索 AI 的无限可能</p>
          </div>

          {/* 错误提示 */}
          {(localError || error) && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-xl text-red-600 text-sm">
              {localError || error}
            </div>
          )}

          {/* 表单 */}
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
                邮箱
              </label>
              <input
                type="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder="your@email.com"
                className="w-full px-4 py-3 bg-white border border-[var(--border)] rounded-xl text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
                密码
              </label>
              <input
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="至少 6 个字符"
                className="w-full px-4 py-3 bg-white border border-[var(--border)] rounded-xl text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-[var(--foreground)] mb-2">
                确认密码
              </label>
              <input
                type="password"
                value={confirmPassword}
                onChange={e => setConfirmPassword(e.target.value)}
                placeholder="再次输入密码"
                className="w-full px-4 py-3 bg-white border border-[var(--border)] rounded-xl text-[var(--foreground)] placeholder:text-[var(--text-muted)] focus:outline-none focus:border-[var(--primary)]"
              />
            </div>

            <div className="text-sm text-[var(--text-muted)]">
              注册即表示同意{' '}
              <button type="button" className="text-[var(--primary)] hover:underline">服务条款</button>
              {' '}和{' '}
              <button type="button" className="text-[var(--primary)] hover:underline">隐私政策</button>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-3 bg-[var(--primary)] text-white rounded-xl font-semibold hover:bg-[var(--primary-dark)] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isLoading ? (
                <span className="flex items-center justify-center gap-2">
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  注册中...
                </span>
              ) : (
                '注册'
              )}
            </button>
          </form>

          {/* 分隔线 */}
          <div className="relative my-6">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-[var(--border)]" />
            </div>
            <div className="relative flex justify-center text-xs">
              <span className="px-4 bg-[var(--background)] text-[var(--text-muted)]">或者</span>
            </div>
          </div>

          {/* 第三方注册 */}
          <div className="space-y-3">
            {/* Google */}
            <button
              type="button"
              onClick={() => signInWithOAuth('google')}
              disabled={isLoading}
              className="w-full py-3 bg-white border border-[var(--border)] text-[var(--foreground)] rounded-xl font-medium hover:bg-[var(--background)] transition-colors flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none">
                <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
                <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
                <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
              </svg>
              使用 Google 注册
            </button>

            {/* Facebook */}
            <button
              type="button"
              onClick={() => signInWithOAuth('facebook')}
              disabled={isLoading}
              className="w-full py-3 bg-[#1877F2] border border-[#1877F2] text-white rounded-xl font-medium hover:bg-[#166FE5] transition-colors flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <svg className="w-5 h-5" viewBox="0 0 24 24" fill="white">
                <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
              </svg>
              使用 Facebook 注册
            </button>
          </div>

          {/* 登录链接 */}
          <p className="mt-6 text-center text-sm text-[var(--text-secondary)]">
            已有账号？{' '}
            <Link href="/web/auth/login" className="text-[var(--primary)] font-medium hover:underline">
              立即登录
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}