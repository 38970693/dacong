'use client';

import { useState } from 'react';

const tabs = [
  { id: 'home', label: '首页', icon: 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6' },
  { id: 'forum', label: '论坛', icon: 'M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z' },
  { id: 'messages', label: '消息', icon: 'M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z' },
  { id: 'profile', label: '我的', icon: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z' },
];

interface TabBarProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
}

export function TabBar({ activeTab, onTabChange }: TabBarProps) {
  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 pb-[env(safe-area-inset-bottom)] bg-white/95 backdrop-blur-xl border-t border-[var(--border)] shadow-[0_-4px_20px_rgba(0,0,0,0.05)]">
      <div className="max-w-lg mx-auto flex justify-around items-center h-16">
        {tabs.map((tab) => {
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => onTabChange(tab.id)}
              className={`flex flex-col items-center justify-center w-full h-full transition-all duration-300 relative ${
                isActive ? 'text-[var(--primary)]' : 'text-[var(--text-muted)]'
              }`}
            >
              {/* 活跃指示器 */}
              {isActive && (
                <span className="absolute -top-0.5 left-1/2 -translate-x-1/2 w-8 h-1 bg-gradient-to-r from-[var(--gradient-amber)] to-[var(--gradient-pink)] rounded-full animate-fade-in-up" />
              )}

              <svg
                className={`w-6 h-6 transition-all duration-300 ${isActive ? 'scale-110' : ''}`}
                fill={isActive ? "currentColor" : "none"}
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={isActive ? 0 : 1.5}
              >
                <path strokeLinecap="round" strokeLinejoin="round" d={tab.icon} />
              </svg>

              <span className={`text-[11px] mt-1 font-semibold transition-all duration-300 ${
                isActive ? 'font-bold' : ''
              }`}>
                {tab.label}
              </span>
            </button>
          );
        })}
      </div>
    </nav>
  );
}
