'use client';

import { useState } from 'react';

const tabs = [
  { id: 'home', label: '首页', icon: '🏠' },
  { id: 'discover', label: '发现', icon: '🔥' },
  { id: 'messages', label: '消息', icon: '💬' },
  { id: 'profile', label: '我的', icon: '👤' },
];

interface TabBarProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
}

export default function TabBar({ activeTab, onTabChange }: TabBarProps) {
  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-black/95 backdrop-blur-sm border-t border-white/10">
      <div className="max-w-lg mx-auto flex justify-around items-center h-14">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => onTabChange(tab.id)}
            className={`flex flex-col items-center justify-center w-full py-1 transition-colors ${
              activeTab === tab.id ? 'text-[#ff6b35]' : 'text-white/60'
            }`}
          >
            <span className="text-xl">{tab.icon}</span>
            <span className="text-[10px] mt-0.5 font-medium">{tab.label}</span>
          </button>
        ))}
      </div>
    </nav>
  );
}
