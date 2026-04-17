'use client';

import { useState } from 'react';

interface ContentItem {
  id: number;
  author: string;
  avatar: string;
  title: string;
  content: string;
  likes: number;
  comments: number;
  shares: number;
}

const mockContent: ContentItem[] = [
  {
    id: 1,
    author: '打工小王',
    avatar: '👨‍💼',
    title: '今天加班到凌晨的心得',
    content: '又是被需求支配的一天...',
    likes: 1234,
    comments: 89,
    shares: 12,
  },
  {
    id: 2,
    author: '产品小李',
    avatar: '👩‍💻',
    title: '程序员和产品经理的日常',
    content: '这个需求很简单，就改一行代码',
    likes: 5678,
    comments: 234,
    shares: 56,
  },
  {
    id: 3,
    author: '测试小张',
    avatar: '🧪',
    title: '上线前夜的测试报告',
    content: '在线等，挺急的',
    likes: 999,
    comments: 67,
    shares: 8,
  },
];

function formatNumber(n: number): string {
  if (n >= 10000) return (n / 10000).toFixed(1) + 'w';
  if (n >= 1000) return (n / 1000).toFixed(1) + 'k';
  return n.toString();
}

export default function HomeFeed() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [contents] = useState<ContentItem[]>(mockContent);

  const handleScroll = (e: React.UIEvent<HTMLDivElement>) => {
    const { scrollTop, clientHeight } = e.currentTarget;
    const index = Math.round(scrollTop / clientHeight);
    setCurrentIndex(index);
  };

  const content = contents[currentIndex] || contents[0];

  return (
    <div className="h-full bg-black relative">
      {/* 顶部状态栏占位 */}
      <div className="absolute top-0 left-0 right-0 z-10 h-11 bg-gradient-to-b from-black/60 to-transparent" />
      
      {/* 内容区 */}
      <div 
        className="content-scroll h-full hide-scrollbar"
        onScroll={handleScroll}
      >
        {contents.map((item, idx) => (
          <div key={item.id} className="h-[100dvh] w-full flex items-end relative">
            {/* 背景占位 */}
            <div className="absolute inset-0 bg-gradient-to-br from-zinc-900 to-black flex items-center justify-center">
              <span className="text-9xl opacity-10">{item.avatar}</span>
            </div>
            
            {/* 内容 */}
            <div className="relative z-10 p-4 pb-20 w-full">
              {/* 作者信息 */}
              <div className="flex items-center gap-3 mb-3">
                <div className="w-12 h-12 rounded-full bg-zinc-800 flex items-center justify-center text-2xl">
                  {item.avatar}
                </div>
                <div>
                  <p className="font-semibold text-white">{item.author}</p>
                  <p className="text-xs text-white/60">刚刚</p>
                </div>
              </div>
              
              {/* 文字内容 */}
              <h2 className="text-lg font-bold text-white mb-2">{item.title}</h2>
              <p className="text-sm text-white/80 mb-4">{item.content}</p>
              
              {/* 话题标签 */}
              <div className="flex gap-2 flex-wrap">
                <span className="px-3 py-1 bg-white/10 rounded-full text-xs text-white/80">#打工日常</span>
                <span className="px-3 py-1 bg-white/10 rounded-full text-xs text-white/80">#职场故事</span>
              </div>
            </div>
            
            {/* 右侧互动栏 */}
            <div className="absolute right-4 bottom-32 flex flex-col items-center gap-6">
              <button className="flex flex-col items-center">
                <span className="text-3xl">❤️</span>
                <span className="text-xs text-white/80 mt-1">{formatNumber(item.likes)}</span>
              </button>
              <button className="flex flex-col items-center">
                <span className="text-3xl">💬</span>
                <span className="text-xs text-white/80 mt-1">{formatNumber(item.comments)}</span>
              </button>
              <button className="flex flex-col items-center">
                <span className="text-3xl">↗️</span>
                <span className="text-xs text-white/80 mt-1">{formatNumber(item.shares)}</span>
              </button>
            </div>
          </div>
        ))}
      </div>
      
      {/* 底部指示器 */}
      <div className="absolute bottom-16 left-1/2 -translate-x-1/2 flex gap-1.5 z-10">
        {contents.map((_, idx) => (
          <div
            key={idx}
            className={`h-1 rounded-full transition-all ${
              idx === currentIndex ? 'w-4 bg-[#ff6b35]' : 'w-1 bg-white/40'
            }`}
          />
        ))}
      </div>
    </div>
  );
}
