'use client';

import { useState } from 'react';
import { createSupabaseClient } from '@/utils/supabase/client';
import { TabBar } from '@/components/TabBar';
import { PostList } from '@/components/PostList';
import { TrendingList } from '@/components/TrendingList';
import { Messages } from '@/components/Messages';
import { Profile } from '@/components/Profile';
import { useUserStore } from '@/stores';

export default function Home() {
  const [activeTab, setActiveTab] = useState('home');
  const { setUser } = useUserStore();
  const supabase = createSupabaseClient();

  const handleLogin = async () => {
    try {
      // 暂时使用匿名登录，后续添加 Google/Apple 登录
      const { data, error } = await supabase.auth.signInAnonymously();
      if (error) throw error;
      if (data.user) {
        setUser(data.user.id, 'user');
      }
    } catch (error) {
      console.error('Login failed:', error);
    }
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'home':
        return <PostList />;
      case 'trending':
        return <TrendingList />;
      case 'messages':
        return <Messages />;
      case 'profile':
        return <Profile onLogin={handleLogin} />;
      default:
        return <PostList />;
    }
  };

  return (
    <div className="min-h-screen bg-[var(--background)] flex flex-col max-w-lg mx-auto relative">
      {/* 顶部搜索栏 */}
      <header className="sticky top-0 z-20 bg-white/95 backdrop-blur-lg border-b border-[var(--border)] px-5 py-3">
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold text-[var(--foreground)]">
            Da<span className="text-[var(--primary)]">Cong</span>
          </h1>
          <button className="w-10 h-10 rounded-full bg-[var(--primary-light)] flex items-center justify-center">
            <svg className="w-5 h-5 text-[var(--primary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
            </svg>
          </button>
        </div>
      </header>

      {/* 主内容区 */}
      <main className="flex-1 overflow-hidden pb-16">
        {renderContent()}
      </main>

      {/* 底部导航 */}
      <TabBar activeTab={activeTab} onTabChange={setActiveTab} />
    </div>
  );
}