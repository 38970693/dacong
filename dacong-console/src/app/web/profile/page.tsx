'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore, useFavoritesStore } from '@/stores';
import { FeedbackModal } from '@/components/FeedbackModal';

export default function ProfilePage() {
  const router = useRouter();
  const { user, isAuthenticated, isLoading: authLoading, signOut, initialize } = useAuthStore();
  const { favorites } = useFavoritesStore();
  const [showFeedback, setShowFeedback] = useState(false);
  const [isInitialized, setIsInitialized] = useState(false);

  useEffect(() => {
    initialize().then(() => setIsInitialized(true));
  }, [initialize]);

  // 用户数据
  const userData = {
    name: user?.email?.split('@')[0] || '用户',
    avatar: '👤',
    bio: user?.email || 'DaCong 用户',
    joinedAt: user?.created_at ? new Date(user.created_at).toLocaleDateString('zh-CN') : '未知',
  };

  // 处理退出登录
  const handleSignOut = async () => {
    await signOut();
    router.push('/web');
  };

  // 未初始化状态
  if (!isInitialized || authLoading) {
    return (
      <div className="pb-16 md:pb-0">
        <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
          <h1 className="text-lg font-bold text-[var(--foreground)]">个人资料</h1>
        </div>
        <div className="p-8 flex items-center justify-center">
          <div className="w-8 h-8 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin"></div>
        </div>
      </div>
    );
  }

  // 未登录状态 - 仍然显示帮助与反馈
  if (!isAuthenticated || !user) {
    return (
      <div className="pb-16 md:pb-0">
        <FeedbackModal isOpen={showFeedback} onClose={() => setShowFeedback(false)} />

        <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
          <h1 className="text-lg font-bold text-[var(--foreground)]">个人资料</h1>
        </div>

        {/* 功能列表（未登录） */}
        <div className="p-4 md:p-5 space-y-3">
          {/* 快捷功能 */}
          <div>
            <h3 className="text-xs text-[var(--text-muted)] uppercase tracking-wider mb-2 px-2">快捷功能</h3>
            <div className="bg-white rounded-xl border border-[var(--border)] overflow-hidden">
              <button
                onClick={() => router.push('/web/auth/login')}
                className="w-full flex items-center gap-4 p-4 hover:bg-[var(--background)] transition-colors"
              >
                <div className="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center">
                  <span className="text-xl">🔖</span>
                </div>
                <div className="flex-1 text-left">
                  <div className="text-sm font-medium text-[var(--foreground)]">我的收藏</div>
                  <div className="text-xs text-[var(--text-muted)]">登录后查看收藏内容</div>
                </div>
                <svg className="w-5 h-5 text-[var(--text-muted)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                </svg>
              </button>

              <div className="border-t border-[var(--border)]" />

              <button
                onClick={() => router.push('/web/auth/login')}
                className="w-full flex items-center gap-4 p-4 hover:bg-[var(--background)] transition-colors"
              >
                <div className="w-10 h-10 rounded-xl bg-green-100 flex items-center justify-center">
                  <span className="text-xl">✍️</span>
                </div>
                <div className="flex-1 text-left">
                  <div className="text-sm font-medium text-[var(--foreground)]">写评测</div>
                  <div className="text-xs text-[var(--text-muted)]">登录后分享你的 AI 使用体验</div>
                </div>
                <svg className="w-5 h-5 text-[var(--text-muted)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                </svg>
              </button>
            </div>
          </div>

          {/* 帮助与反馈 */}
          <div>
            <h3 className="text-xs text-[var(--text-muted)] uppercase tracking-wider mb-2 px-2">帮助与反馈</h3>
            <div className="bg-white rounded-xl border border-[var(--border)] overflow-hidden">
              <button
                onClick={() => setShowFeedback(true)}
                className="w-full flex items-center gap-4 p-4 hover:bg-[var(--background)] transition-colors"
              >
                <div className="w-10 h-10 rounded-xl bg-orange-100 flex items-center justify-center">
                  <span className="text-xl">💬</span>
                </div>
                <div className="flex-1 text-left">
                  <div className="text-sm font-medium text-[var(--foreground)]">帮助与反馈</div>
                  <div className="text-xs text-[var(--text-muted)]">功能建议、问题反馈、商务合作</div>
                </div>
                <svg className="w-5 h-5 text-[var(--text-muted)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                </svg>
              </button>

              <div className="border-t border-[var(--border)]" />

              <a
                href="https://github.com/dacong/dacong-console/issues"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full flex items-center gap-4 p-4 hover:bg-[var(--background)] transition-colors"
              >
                <div className="w-10 h-10 rounded-xl bg-gray-100 flex items-center justify-center">
                  <span className="text-xl">🐛</span>
                </div>
                <div className="flex-1 text-left">
                  <div className="text-sm font-medium text-[var(--foreground)]">报告 Bug</div>
                  <div className="text-xs text-[var(--text-muted)]">在 GitHub 上提交问题</div>
                </div>
                <svg className="w-5 h-5 text-[var(--text-muted)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                </svg>
              </a>

              <div className="border-t border-[var(--border)]" />

              <a
                href="mailto:dacong@example.com"
                className="w-full flex items-center gap-4 p-4 hover:bg-[var(--background)] transition-colors"
              >
                <div className="w-10 h-10 rounded-xl bg-purple-100 flex items-center justify-center">
                  <span className="text-xl">📧</span>
                </div>
                <div className="flex-1 text-left">
                  <div className="text-sm font-medium text-[var(--foreground)]">联系我们</div>
                  <div className="text-xs text-[var(--text-muted)]">发送邮件至 dacong@example.com</div>
                </div>
                <svg className="w-5 h-5 text-[var(--text-muted)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                </svg>
              </a>
            </div>
          </div>

          {/* 关于 */}
          <div>
            <h3 className="text-xs text-[var(--text-muted)] uppercase tracking-wider mb-2 px-2">关于</h3>
            <div className="bg-white rounded-xl border border-[var(--border)] overflow-hidden">
              <div className="flex items-center gap-4 p-4">
                <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[var(--gradient-amber)] to-[var(--gradient-pink)] flex items-center justify-center">
                  <span className="text-lg font-bold text-white">AI</span>
                </div>
                <div className="flex-1 text-left">
                  <div className="text-sm font-medium text-[var(--foreground)]">DaCong Console</div>
                  <div className="text-xs text-[var(--text-muted)]">版本 1.0.0</div>
                </div>
              </div>
            </div>
          </div>

          {/* 登录提示 */}
          <div className="pt-4 pb-2 text-center">
            <p className="text-sm text-[var(--text-muted)] mb-3">登录后解锁更多功能</p>
            <div className="flex flex-col gap-2 max-w-xs mx-auto">
              <button
                onClick={() => router.push('/web/auth/login')}
                className="px-6 py-2.5 bg-[var(--primary)] text-white rounded-full font-semibold"
              >
                登录
              </button>
              <button
                onClick={() => router.push('/web/auth/register')}
                className="px-6 py-2.5 bg-white border border-[var(--border)] text-[var(--foreground)] rounded-full font-medium"
              >
                注册
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="pb-16 md:pb-0">
      {/* 反馈模态框 */}
      <FeedbackModal isOpen={showFeedback} onClose={() => setShowFeedback(false)} />

      {/* 页面标题 */}
      <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        <h1 className="text-lg font-bold text-[var(--foreground)]">个人资料</h1>
      </div>

      {/* 用户信息卡片 */}
      <div className="p-4 md:p-6 text-center border-b border-[var(--border)]">
        <div className="w-20 h-20 md:w-24 md:h-24 mx-auto mb-4 rounded-2xl bg-[var(--primary-light)] flex items-center justify-center text-4xl md:text-5xl shadow-lg">
          {userData.avatar}
        </div>
        <h2 className="text-xl md:text-2xl font-bold text-[var(--foreground)]">{userData.name}</h2>
        <p className="text-sm text-[var(--text-secondary)] mt-2">{userData.bio}</p>
        <p className="text-xs text-[var(--text-muted)] mt-1">加入于 {userData.joinedAt}</p>

        {/* 操作按钮 */}
        <div className="flex gap-2 md:gap-3 mt-4 md:mt-6 justify-center">
          <button
            onClick={handleSignOut}
            className="px-4 md:px-6 py-2 md:py-2.5 bg-[var(--foreground)] text-white rounded-full font-medium text-sm"
          >
            退出登录
          </button>
        </div>
      </div>

      {/* 功能列表 */}
      <div className="p-4 md:p-5 space-y-3">
        {/* 快捷功能 */}
        <div>
          <h3 className="text-xs text-[var(--text-muted)] uppercase tracking-wider mb-2 px-2">快捷功能</h3>
          <div className="bg-white rounded-xl border border-[var(--border)] overflow-hidden">
            <button
              onClick={() => router.push('/web/saved')}
              className="w-full flex items-center gap-4 p-4 hover:bg-[var(--background)] transition-colors"
            >
              <div className="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center">
                <span className="text-xl">🔖</span>
              </div>
              <div className="flex-1 text-left">
                <div className="text-sm font-medium text-[var(--foreground)]">我的收藏</div>
                <div className="text-xs text-[var(--text-muted)]">查看收藏的帖子和内容</div>
              </div>
              <svg className="w-5 h-5 text-[var(--text-muted)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
              </svg>
            </button>

            <div className="border-t border-[var(--border)]" />

            <button
              onClick={() => router.push('/web/review/new')}
              className="w-full flex items-center gap-4 p-4 hover:bg-[var(--background)] transition-colors"
            >
              <div className="w-10 h-10 rounded-xl bg-green-100 flex items-center justify-center">
                <span className="text-xl">✍️</span>
              </div>
              <div className="flex-1 text-left">
                <div className="text-sm font-medium text-[var(--foreground)]">写评测</div>
                <div className="text-xs text-[var(--text-muted)]">分享你的 AI 产品使用体验</div>
              </div>
              <svg className="w-5 h-5 text-[var(--text-muted)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
              </svg>
            </button>
          </div>
        </div>

        {/* 帮助与反馈 */}
        <div>
          <h3 className="text-xs text-[var(--text-muted)] uppercase tracking-wider mb-2 px-2">帮助与反馈</h3>
          <div className="bg-white rounded-xl border border-[var(--border)] overflow-hidden">
            <button
              onClick={() => setShowFeedback(true)}
              className="w-full flex items-center gap-4 p-4 hover:bg-[var(--background)] transition-colors"
            >
              <div className="w-10 h-10 rounded-xl bg-orange-100 flex items-center justify-center">
                <span className="text-xl">💬</span>
              </div>
              <div className="flex-1 text-left">
                <div className="text-sm font-medium text-[var(--foreground)]">帮助与反馈</div>
                <div className="text-xs text-[var(--text-muted)]">功能建议、问题反馈、商务合作</div>
              </div>
              <svg className="w-5 h-5 text-[var(--text-muted)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
              </svg>
            </button>

            <div className="border-t border-[var(--border)]" />

            <a
              href="https://github.com/dacong/dacong-console/issues"
              target="_blank"
              rel="noopener noreferrer"
              className="w-full flex items-center gap-4 p-4 hover:bg-[var(--background)] transition-colors"
            >
              <div className="w-10 h-10 rounded-xl bg-gray-100 flex items-center justify-center">
                <span className="text-xl">🐛</span>
              </div>
              <div className="flex-1 text-left">
                <div className="text-sm font-medium text-[var(--foreground)]">报告 Bug</div>
                <div className="text-xs text-[var(--text-muted)]">在 GitHub 上提交问题</div>
              </div>
              <svg className="w-5 h-5 text-[var(--text-muted)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
            </a>

            <div className="border-t border-[var(--border)]" />

            <a
              href="mailto:dacong@example.com"
              className="w-full flex items-center gap-4 p-4 hover:bg-[var(--background)] transition-colors"
            >
              <div className="w-10 h-10 rounded-xl bg-purple-100 flex items-center justify-center">
                <span className="text-xl">📧</span>
              </div>
              <div className="flex-1 text-left">
                <div className="text-sm font-medium text-[var(--foreground)]">联系我们</div>
                <div className="text-xs text-[var(--text-muted)]">发送邮件至 dacong@example.com</div>
              </div>
              <svg className="w-5 h-5 text-[var(--text-muted)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
            </a>
          </div>
        </div>

        {/* 关于 */}
        <div>
          <h3 className="text-xs text-[var(--text-muted)] uppercase tracking-wider mb-2 px-2">关于</h3>
          <div className="bg-white rounded-xl border border-[var(--border)] overflow-hidden">
            <div className="flex items-center gap-4 p-4">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[var(--gradient-amber)] to-[var(--gradient-pink)] flex items-center justify-center">
                <span className="text-lg font-bold text-white">AI</span>
              </div>
              <div className="flex-1 text-left">
                <div className="text-sm font-medium text-[var(--foreground)]">DaCong Console</div>
                <div className="text-xs text-[var(--text-muted)]">版本 1.0.0</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}