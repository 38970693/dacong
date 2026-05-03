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
        <div className="w-6 h-6 border-2 border-orange-500 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-full text-zinc-500">
        <p className="mb-4">{error}</p>
        <button
          onClick={refreshAll}
          className="px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600"
        >
          重试
        </button>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col">
      {/* 标题 */}
      <div className="p-4 pb-2">
        <h2 className="text-xl font-bold text-white">🔥 热门榜单</h2>
        <p className="text-xs text-zinc-500 mt-1">每30秒自动更新</p>
      </div>

      {/* 切换标签 */}
      <div className="flex gap-2 px-4 mb-2">
        <button
          onClick={() => setActiveTab('hot')}
          className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${
            activeTab === 'hot'
              ? 'bg-orange-500 text-white'
              : 'bg-zinc-800 text-zinc-400 hover:bg-zinc-700'
          }`}
        >
          🌡️ 热榜
        </button>
        <button
          onClick={() => setActiveTab('new')}
          className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${
            activeTab === 'new'
              ? 'bg-orange-500 text-white'
              : 'bg-zinc-800 text-zinc-400 hover:bg-zinc-700'
          }`}
        >
          ✨ 最新
        </button>
      </div>

      {/* 列表 */}
      <div className="flex-1 overflow-y-auto p-4 pt-2">
        {activeTab === 'hot' && hot.length > 0 && (
          <div className="space-y-2 mb-4">
            {/* Top 3 突出显示 */}
            {hot.slice(0, 3).map((item, idx) => (
              <div key={item.id} className="flex items-center gap-3 bg-gradient-to-r from-orange-500/20 to-transparent p-3 rounded-lg">
                <span className={`text-2xl font-bold ${
                  idx === 0 ? 'text-yellow-400' : idx === 1 ? 'text-zinc-300' : 'text-orange-400'
                }`}>
                  {idx + 1}
                </span>
                <div className="flex-1 min-w-0">
                  <p className="text-white font-medium truncate">{item.title}</p>
                  <p className="text-xs text-zinc-500">{item.source} • ❤️ {item.likes}</p>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* 完整列表 */}
        {currentList.map((item, idx) => (
          <div key={item.id} className="mb-3">
            {activeTab === 'hot' && (
              <div className="flex items-start gap-3">
                <span className="text-zinc-600 font-bold w-6 text-center">{idx + 1}</span>
                <div className="flex-1">
                  <PostCard post={item} />
                </div>
              </div>
            )}
            {activeTab === 'new' && <PostCard post={item} />}
          </div>
        ))}

        {currentList.length === 0 && (
          <p className="text-center text-zinc-500 py-8">暂无数据</p>
        )}
      </div>
    </div>
  );
}