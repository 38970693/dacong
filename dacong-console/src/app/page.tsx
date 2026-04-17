'use client';

import { useState } from 'react';
import TabBar from '@/components/TabBar';
import HomeFeed from '@/components/HomeFeed';
import Discover from '@/components/Discover';
import Messages from '@/components/Messages';
import Profile from '@/components/Profile';

export default function Home() {
  const [activeTab, setActiveTab] = useState('home');

  const renderContent = () => {
    switch (activeTab) {
      case 'home':
        return <HomeFeed />;
      case 'discover':
        return <Discover />;
      case 'messages':
        return <Messages />;
      case 'profile':
        return <Profile />;
      default:
        return <HomeFeed />;
    }
  };

  return (
    <div className="min-h-screen bg-black flex flex-col max-w-lg mx-auto relative">
      {/* 主内容区 */}
      <main className="flex-1 overflow-hidden">
        {renderContent()}
      </main>
      
      {/* 底部导航 */}
      <TabBar activeTab={activeTab} onTabChange={setActiveTab} />
    </div>
  );
}
