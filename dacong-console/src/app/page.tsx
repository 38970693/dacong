'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
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
  const router = useRouter();

  const handleLogin = async () => {
    try {
      const { data, error } = await supabase.auth.signInAnonymously();
      if (error) throw error;
      if (data.user) {
        setUser(data.user.id, 'user');
      }
    } catch (error) {
      console.error('Login failed:', error);
    }
  };

  const handleSearchClick = () => {
    router.push('/web/search');
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
      {/* 顶部导航栏 - 适配 iOS 安全区域 */}
      <header className="sticky top-0 z-20 pt-[env(safe-area-inset-top)] bg-white/95 backdrop-blur-xl border-b border-[var(--border)]">
        <div className="px-5 py-3 flex items-center justify-between">
          {/* Logo */}
          <div className="flex items-center gap-2">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-[var(--gradient-amber)] to-[var(--gradient-pink)] flex items-center justify-center">
              <span className="text-white font-bold text-sm">AI</span>
            </div>
            <h1 className="text-lg font-bold">
              Da<span className="bg-gradient-to-r from-[var(--gradient-amber)] to-[var(--gradient-pink)] bg-clip-text text-transparent">Cong</span>
            </h1>
          </div>

          {/* 操作按钮 */}
          <div className="flex items-center gap-2">
            <button
              onClick={handleSearchClick}
              className="w-10 h-10 rounded-xl bg-[var(--background)] border border-[var(--border)] flex items-center justify-center hover:border-[var(--primary)] transition-colors"
            >
              <svg className="w-5 h-5 text-[var(--text-secondary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
              </svg>
            </button>
            <button className="w-10 h-10 rounded-xl gradient-btn flex items-center justify-center">
              <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
              </svg>
            </button>
          </div>
        </div>

        {/* 分类标签 */}
        <div className="px-5 pb-3 flex gap-2 overflow-x-auto hide-scrollbar">
          <button className="px-4 py-2 rounded-full text-sm font-semibold gradient-btn text-white whitespace-nowrap">
            全部
          </button>
          <button className="px-4 py-2 rounded-full text-sm font-medium bg-white border border-[var(--border)] text-[var(--text-secondary)] whitespace-nowrap hover:border-[var(--primary)] hover:text-[var(--foreground)] transition-colors">
            🤖 AI 模型
          </button>
          <button className="px-4 py-2 rounded-full text-sm font-medium bg-white border border-[var(--border)] text-[var(--text-secondary)] whitespace-nowrap hover:border-[var(--primary)] hover:text-[var(--foreground)] transition-colors">
            📰 科技资讯
          </button>
          <button className="px-4 py-2 rounded-full text-sm font-medium bg-white border border-[var(--border)] text-[var(--text-secondary)] whitespace-nowrap hover:border-[var(--primary)] hover:text-[var(--foreground)] transition-colors">
            💡 深度解读
          </button>
        </div>
      </header>

      {/* 主内容区 */}
      <main className="flex-1 overflow-y-auto overscroll-y-contain" style={{ height: '100dvh' }}>
        {renderContent()}
      </main>

      {/* 底部导航 */}
      <TabBar activeTab={activeTab} onTabChange={setActiveTab} />
    </div>
  );
}
