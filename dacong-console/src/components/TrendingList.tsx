'use client';

import { useEffect, useState } from 'react';
import type { Post } from '@/types/database';
import { PostCard } from './PostCard';
import { useTrendingStore } from '@/stores';

export function TrendingList() {
  const { hot, new: newPosts, isLoading, error, refreshAll } = useTrendingStore();
  const [activeTab, setActiveTab] = useState<'hot' | 'new'>('hot');

  // 初始化加载
  useEffect(() => {
    refreshAll();
  }, [refreshAll]);

  // 30秒轮询
  useEffect(() => {
    const interval = setInterval(refreshAll, 30000);
    return () => clearInterval(interval);
  }, [refreshAll]);

  const currentList = activeTab === 'hot' ? hot : newPosts;

  if (isLoading && currentList.length === 0) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="loading-spinner" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="empty-state">
        <div className="w-16 h-16 mb-4 rounded-full bg-[var(--primary-light)] flex items-center justify-center">
          <svg className="w-8 h-8 text-[var(--primary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
          </svg>
        </div>
        <p className="text-[var(--text-secondary)] mb-4">{error}</p>
        <button
          onClick={refreshAll}
          className="px-6 py-2.5 bg-[var(--primary)] text-white rounded-full font-medium btn-hover"
        >
          重试
        </button>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col bg-[var(--background)]">
      {/* 标题区 */}
      <div className="p-5 pb-3 bg-white border-b border-[var(--border)]">
        <h2 className="text-xl font-bold text-[var(--foreground)] flex items-center gap-2">
          <span>🔥</span>
          <span>热门榜单</span>
        </h2>
        <p className="text-xs text-[var(--text-muted)] mt-1">每30秒自动更新</p>
      </div>

      {/* 切换标签 */}
      <div className="flex gap-3 px-5 py-4">
        <button
          onClick={() => setActiveTab('hot')}
          className={`px-5 py-2 rounded-full text-sm font-semibold transition-all ${
            activeTab === 'hot'
              ? 'bg-[var(--primary)] text-white shadow-lg shadow-[var(--primary)]/30'
              : 'bg-white text-[var(--text-secondary)] border border-[var(--border)] hover:border-[var(--primary)] hover:text-[var(--primary)]'
          }`}
        >
          🌡️ 热榜
        </button>
        <button
          onClick={() => setActiveTab('new')}
          className={`px-5 py-2 rounded-full text-sm font-semibold transition-all ${
            activeTab === 'new'
              ? 'bg-[var(--primary)] text-white shadow-lg shadow-[var(--primary)]/30'
              : 'bg-white text-[var(--text-secondary)] border border-[var(--border)] hover:border-[var(--primary)] hover:text-[var(--primary)]'
          }`}
        >
          ✨ 最新
        </button>
      </div>

      {/* 列表 */}
      <div className="flex-1 overflow-y-auto px-5 pb-20 hide-scrollbar">
        {activeTab === 'hot' && hot.length > 0 && (
          <div className="mb-4">
            {/* Top 3 突出显示 - 排行榜样式 */}
            <div className="bg-white rounded-2xl p-4 mb-4 border border-[var(--border)] shadow-sm">
              <h3 className="text-sm font-semibold text-[var(--text-secondary)] mb-3 flex items-center gap-2">
                <span>🏆</span>
                <span>TOP 3</span>
              </h3>
              <div className="space-y-3">
                {hot.slice(0, 3).map((item, idx) => (
                  <div
                    key={item.id}
                    className={`flex items-center gap-4 p-3 rounded-xl transition-all card-hover ${
                      idx === 0 ? 'bg-[var(--primary-light)]' : 'bg-[var(--background)]'
                    }`}
                  >
                    <span className={`text-3xl font-bold w-10 text-center ${
                      idx === 0 ? 'text-[var(--primary)]' : idx === 1 ? 'text-[var(--text-muted)]' : 'text-[var(--primary-dark)]'
                    }`}>
                      {idx + 1}
                    </span>
                    <div className="flex-1 min-w-0">
                      <p className="font-semibold text-[var(--foreground)] truncate">{item.title}</p>
                      <p className="text-xs text-[var(--text-muted)] mt-1">
                        {item.source || '综合'} • ❤️ {item.likes}
                      </p>
                    </div>
                    {idx === 0 && (
                      <span className="px-2 py-1 bg-[var(--primary)] text-white text-xs rounded-full font-medium">热</span>
                    )}
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* 完整列表 */}
        {currentList.map((item, idx) => (
          <div key={item.id} className="mb-3 animate-fade-in-up" style={{ animationDelay: `${idx * 30}ms` }}>
            {activeTab === 'hot' ? (
              <div className="flex items-start gap-3">
                <span className="text-[var(--text-muted)] font-bold w-6 text-center pt-3 text-lg">{idx + 4}</span>
                <div className="flex-1">
                  <PostCard post={item} />
                </div>
              </div>
            ) : (
              <PostCard post={item} />
            )}
          </div>
        ))}

        {currentList.length === 0 && (
          <div className="empty-state">
            <div className="w-16 h-16 mb-4 rounded-xl bg-[var(--primary-light)] flex items-center justify-center">
              <span className="text-3xl">📊</span>
            </div>
            <p className="text-[var(--text-secondary)]">暂无数据</p>
          </div>
        )}
      </div>
    </div>
  );
}