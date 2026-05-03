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
    <div className="min-h-screen bg-black flex flex-col max-w-lg mx-auto relative">
      {/* 主内容区 */}
      <main className="flex-1 overflow-hidden pb-16">
        {renderContent()}
      </main>

      {/* 底部导航 */}
      <TabBar activeTab={activeTab} onTabChange={setActiveTab} />
    </div>
  );
}