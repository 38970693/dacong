'use client';

import { useState } from 'react';
import { useUserStore } from '@/stores';

const tabs = [
  { id: 'saved', label: '收藏', icon: '🔖' },
  { id: 'following', label: '关注', icon: '💗' },
  { id: 'activities', label: '动态', icon: '📝' },
];

export default function ProfilePage() {
  const { isAuthenticated } = useUserStore();
  const [activeTab, setActiveTab] = useState('saved');

  const mockUser = {
    name: 'AI 爱好者',
    avatar: '👤',
    bio: '正在探索 AI 的无限可能',
    posts: 12,
    followers: 456,
    following: 789,
    likes: 1234,
  };

  const mockActivities = [
    { id: '1', title: '收藏了 Claude 3 发布资讯', time: '2小时前' },
    { id: '2', title: '评论了 GPT-5 预测文章', time: '1天前' },
    { id: '3', title: '关注了 AI 前沿', time: '3天前' },
  ];

  const mockSavedPosts = [
    { id: '1', title: 'Claude 3 发布：超越 GPT-4 的多模态 AI 助手', source: 'HackerNews', savedAt: '2小时前' },
    { id: '2', title: 'GPT-5 即将发布？OpenAI 工程师透露新进展', source: 'Reddit', savedAt: '1天前' },
  ];

  const mockFollowing = [
    { id: '1', name: 'AI 前沿', avatar: '🤖', followers: 1234 },
    { id: '2', name: '科技日报', avatar: '📰', followers: 5678 },
  ];

  if (!isAuthenticated) {
    return (
      <div className="pb-16 md:pb-0">
        <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
          <h1 className="text-lg font-bold text-[var(--foreground)]">个人资料</h1>
        </div>
        <div className="p-6 md:p-8 text-center">
          <div className="w-20 h-20 md:w-24 md:h-24 mx-auto mb-4 md:mb-6 rounded-2xl bg-[var(--primary-light)] flex items-center justify-center">
            <svg className="w-10 h-10 md:w-12 md:h-12 text-[var(--primary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
            </svg>
          </div>
          <h2 className="text-xl md:text-2xl font-bold text-[var(--foreground)] mb-2">登录 / 注册</h2>
          <p className="text-sm text-[var(--text-secondary)] mb-6 max-w-xs mx-auto">
            登录后可以收藏内容、发表评论，关注感兴趣的创作者
          </p>
          <button className="px-6 md:px-8 py-2.5 md:py-3 bg-[var(--primary)] text-white rounded-full font-semibold btn-hover">
            登录
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="pb-16 md:pb-0">
      {/* 页面标题 */}
      <div className="sticky top-14 md:top-16 z-10 bg-white/95 backdrop-blur-sm px-4 md:px-5 py-3 md:py-4 border-b border-[var(--border)]">
        <h1 className="text-lg font-bold text-[var(--foreground)]">个人资料</h1>
      </div>

      {/* 用户信息卡片 */}
      <div className="p-4 md:p-6 text-center border-b border-[var(--border)]">
        <div className="w-20 h-20 md:w-24 md:h-24 mx-auto mb-4 rounded-2xl bg-[var(--primary-light)] flex items-center justify-center text-4xl md:text-5xl shadow-lg">
          {mockUser.avatar}
        </div>
        <h2 className="text-xl md:text-2xl font-bold text-[var(--foreground)]">{mockUser.name}</h2>
        <p className="text-sm text-[var(--text-secondary)] mt-2">{mockUser.bio}</p>

        {/* 统计 */}
        <div className="flex justify-around md:justify-center md:gap-12 mt-4 md:mt-6 py-3 md:py-4 border-y border-[var(--border)]">
          <div className="text-center">
            <div className="text-xl md:text-2xl font-bold text-[var(--foreground)]">{mockUser.posts}</div>
            <div className="text-xs text-[var(--text-muted)]">发帖</div>
          </div>
          <div className="text-center">
            <div className="text-xl md:text-2xl font-bold text-[var(--foreground)]">{mockUser.followers}</div>
            <div className="text-xs text-[var(--text-muted)]">粉丝</div>
          </div>
          <div className="text-center">
            <div className="text-xl md:text-2xl font-bold text-[var(--foreground)]">{mockUser.following}</div>
            <div className="text-xs text-[var(--text-muted)]">关注</div>
          </div>
          <div className="text-center">
            <div className="text-xl md:text-2xl font-bold text-[var(--foreground)]">{mockUser.likes}</div>
            <div className="text-xs text-[var(--text-muted)]">获赞</div>
          </div>
        </div>

        {/* 操作按钮 */}
        <div className="flex gap-2 md:gap-3 mt-4 md:mt-6 justify-center">
          <button className="px-4 md:px-6 py-2 md:py-2.5 bg-[var(--foreground)] text-white rounded-full font-medium btn-hover text-sm">
            编辑资料
          </button>
          <button className="px-4 md:px-6 py-2 md:py-2.5 bg-white border border-[var(--border)] text-[var(--foreground)] rounded-full font-medium text-sm">
            设置
          </button>
        </div>
      </div>

      {/* Tab 切换 */}
      <div className="flex border-b border-[var(--border)]">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`flex-1 flex items-center justify-center gap-1.5 py-3 text-sm font-medium transition-all ${
              activeTab === tab.id
                ? 'text-[var(--foreground)] border-b-2 border-[var(--foreground)]'
                : 'text-[var(--text-muted)]'
            }`}
          >
            <span>{tab.icon}</span>
            <span>{tab.label}</span>
          </button>
        ))}
      </div>

      {/* Tab 内容 */}
      <div className="p-4 md:p-5">
        {activeTab === 'saved' && (
          <div className="space-y-3">
            {mockSavedPosts.length > 0 ? (
              mockSavedPosts.map((post) => (
                <div key={post.id} className="p-4 bg-white rounded-xl border border-[var(--border)] hover:border-[var(--primary)] transition-colors cursor-pointer">
                  <h4 className="font-medium text-[var(--foreground)] mb-2">{post.title}</h4>
                  <div className="flex items-center justify-between text-xs text-[var(--text-muted)]">
                    <span>{post.source}</span>
                    <span>收藏于 {post.savedAt}</span>
                  </div>
                </div>
              ))
            ) : (
              <div className="text-center py-12 text-[var(--text-muted)]">
                <div className="text-4xl mb-3">🔖</div>
                <p>暂无收藏</p>
              </div>
            )}
          </div>
        )}

        {activeTab === 'following' && (
          <div className="space-y-3">
            {mockFollowing.length > 0 ? (
              mockFollowing.map((user) => (
                <div key={user.id} className="flex items-center gap-3 p-4 bg-white rounded-xl border border-[var(--border)]">
                  <div className="w-12 h-12 rounded-full bg-[var(--primary-light)] flex items-center justify-center text-xl">
                    {user.avatar}
                  </div>
                  <div className="flex-1 min-w-0">
                    <h4 className="font-medium text-[var(--foreground)]">{user.name}</h4>
                    <p className="text-xs text-[var(--text-muted)]">{user.followers} 粉丝</p>
                  </div>
                  <button className="px-3 py-1.5 text-xs font-medium text-[var(--text-muted)] hover:text-[var(--foreground)]">
                    已关注
                  </button>
                </div>
              ))
            ) : (
              <div className="text-center py-12 text-[var(--text-muted)]">
                <div className="text-4xl mb-3">💗</div>
                <p>暂无关注</p>
              </div>
            )}
          </div>
        )}

        {activeTab === 'activities' && (
          <div className="space-y-3">
            {mockActivities.length > 0 ? (
              mockActivities.map((activity) => (
                <div key={activity.id} className="flex items-start gap-3 p-3 bg-white rounded-xl border border-[var(--border)]">
                  <div className="w-9 h-9 rounded-full bg-[var(--primary-light)] flex items-center justify-center shrink-0">
                    📝
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-[var(--foreground)]">{activity.title}</p>
                    <p className="text-xs text-[var(--text-muted)] mt-1">{activity.time}</p>
                  </div>
                </div>
              ))
            ) : (
              <div className="text-center py-12 text-[var(--text-muted)]">
                <div className="text-4xl mb-3">📝</div>
                <p>暂无动态</p>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}