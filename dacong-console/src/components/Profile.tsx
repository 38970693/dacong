'use client';

import { useRouter } from 'next/navigation';
import { useUserStore } from '@/stores';

interface ProfileProps {
  onLogin?: () => void;
}

export function Profile({ onLogin }: ProfileProps) {
  const router = useRouter();
  const { isAuthenticated, userId, role } = useUserStore();

  const handleEditProfile = () => {
    alert('编辑资料功能即将上线...');
  };

  const handleSettings = () => {
    alert('设置功能即将上线...');
  };

  // 未登录状态
  if (!isAuthenticated) {
    return (
      <div className="h-full bg-[var(--background)] flex flex-col items-center justify-center p-8">
        <div className="w-24 h-24 mb-6 rounded-2xl bg-[var(--primary-light)] flex items-center justify-center">
          <svg className="w-12 h-12 text-[var(--primary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
          </svg>
        </div>
        <h2 className="text-2xl font-bold text-[var(--foreground)] mb-2">登录 / 注册</h2>
        <p className="text-sm text-[var(--text-secondary)] mb-8 text-center max-w-xs leading-relaxed">
          登录后可以点赞、评论，关注更多精彩内容
        </p>

        <button
          onClick={onLogin}
          className="w-full max-w-xs py-3.5 bg-[var(--primary)] text-white rounded-full font-semibold btn-hover shadow-lg shadow-[var(--primary)]/20"
        >
          登录
        </button>

        <div className="mt-6 text-xs text-[var(--text-muted)]">
          登录即表示同意用户协议和隐私政策
        </div>
      </div>
    );
  }

  // 已登录状态（mock 数据，后续连接真实用户数据）
  const user = {
    name: '用户',
    avatar: '👤',
    bio: '正在享受 DaCong 的精彩内容',
    fans: 0,
    follow: 0,
    likes: 0,
  };

  const myPosts: { id: string; title: string; likes: number; comments: number }[] = [];

  return (
    <div className="scroll-container-flex flex flex-col bg-[var(--background)]">
      {/* 个人信息区 - 渐变背景 */}
      <div className="bg-gradient-to-b from-white to-[var(--background)] p-6 pt-16 flex-shrink-0">
        <div className="flex items-center gap-5">
          <div className="w-20 h-20 rounded-2xl bg-[var(--primary-light)] flex items-center justify-center text-4xl shadow-lg">
            {user.avatar}
          </div>
          <div>
            <h1 className="text-2xl font-bold text-[var(--foreground)]">{user.name}</h1>
            <p className="text-sm text-[var(--text-secondary)] mt-1">{user.bio}</p>
          </div>
        </div>

        {/* 数据统计 */}
        <div className="flex justify-around mt-6 py-5 border-y border-[var(--border)] bg-white rounded-xl shadow-sm">
          <div className="text-center">
            <p className="text-2xl font-bold text-[var(--foreground)]">{user.fans}</p>
            <p className="text-xs text-[var(--text-muted)] mt-1">粉丝</p>
          </div>
          <div className="w-px bg-[var(--border)]"></div>
          <div className="text-center">
            <p className="text-2xl font-bold text-[var(--foreground)]">{user.follow}</p>
            <p className="text-xs text-[var(--text-muted)] mt-1">关注</p>
          </div>
          <div className="w-px bg-[var(--border)]"></div>
          <div className="text-center">
            <p className="text-2xl font-bold text-[var(--foreground)]">{user.likes}</p>
            <p className="text-xs text-[var(--text-muted)] mt-1">获赞</p>
          </div>
        </div>

        {/* 操作按钮 */}
        <div className="flex gap-3 mt-4">
          <button
            onClick={handleEditProfile}
            className="flex-1 py-2.5 bg-[var(--foreground)] text-white rounded-full font-medium text-sm btn-hover"
          >
            编辑资料
          </button>
          <button
            onClick={handleSettings}
            className="px-5 py-2.5 bg-white border border-[var(--border)] rounded-full text-sm"
          >
            <svg className="w-5 h-5 text-[var(--text-secondary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.388.48.831 1.012 1.096C15.056 6.654 15.822 7 16.5 7H17v3.5c0 1.1-.9 2-2 2h-1a2 2 0 01-2-2v-1H8.5c-.667 0-1.25-.56-1.25-1.125V7.5h1.25c.565 0 1.062-.388 1.11-.94l.212-1.281z" />
              <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          </button>
        </div>
      </div>

      {/* 我的发布 */}
      <div className="p-5">
        <h2 className="font-semibold text-[var(--foreground)] mb-4 flex items-center gap-2">
          <span>我的发布</span>
          <span className="text-xs text-[var(--primary)] bg-[var(--primary-light)] px-2 py-0.5 rounded-full">0</span>
        </h2>
        {myPosts.length === 0 ? (
          <div className="bg-white rounded-xl p-8 text-center border border-[var(--border)] shadow-sm">
            <div className="w-16 h-16 mx-auto mb-4 rounded-xl bg-[var(--primary-light)] flex items-center justify-center">
              <span className="text-3xl">📝</span>
            </div>
            <p className="text-[var(--text-secondary)] mb-2">还没有发布内容</p>
            <p className="text-xs text-[var(--text-muted)]">开始创作你的第一个帖子吧</p>
          </div>
        ) : (
          <div className="space-y-3">
            {myPosts.map((post) => (
              <div key={post.id} className="bg-white rounded-xl p-4 card-hover border border-[var(--border)] shadow-sm">
                <p className="font-medium text-sm text-[var(--foreground)] mb-2">{post.title}</p>
                <div className="flex items-center gap-4 text-xs text-[var(--text-muted)]">
                  <span className="flex items-center gap-1">
                    <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                    </svg>
                    {post.likes}
                  </span>
                  <span className="flex items-center gap-1">
                    <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                    </svg>
                    {post.comments}
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}