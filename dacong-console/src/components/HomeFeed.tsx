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
    <div className="h-full bg-white relative">
      {/* 顶部状态栏占位 - 新设计 */}
      <div className="absolute top-0 left-0 right-0 z-10 h-16 bg-white/80 backdrop-blur-lg border-b border-[var(--border)] flex items-center px-5">
        <h1 className="text-lg font-bold text-[var(--foreground)]">Da<span className="text-[var(--primary)]">Cong</span></h1>
      </div>

      {/* 内容区 */}
      <div
        className="content-scroll h-full hide-scrollbar"
        onScroll={handleScroll}
      >
        {contents.map((item, idx) => (
          <div key={item.id} className="h-[100dvh] w-full flex items-end relative">
            {/* 背景 */}
            <div className="absolute inset-0 bg-gradient-to-br from-[var(--primary-light)] to-white flex items-center justify-center">
              <span className="text-[120px] opacity-10">{item.avatar}</span>
            </div>

            {/* 内容 */}
            <div className="relative z-10 p-5 pb-20 w-full">
              {/* 作者信息 */}
              <div className="flex items-center gap-3 mb-4">
                <div className="w-14 h-14 rounded-2xl bg-white shadow-lg flex items-center justify-center text-3xl">
                  {item.avatar}
                </div>
                <div>
                  <p className="font-bold text-[var(--foreground)] text-lg">{item.author}</p>
                  <p className="text-xs text-[var(--text-muted)]">刚刚</p>
                </div>
              </div>

              {/* 文字内容 */}
              <h2 className="text-xl font-bold text-[var(--foreground)] mb-2 leading-snug">{item.title}</h2>
              <p className="text-sm text-[var(--text-secondary)] mb-4 leading-relaxed">{item.content}</p>

              {/* 话题标签 */}
              <div className="flex gap-2 flex-wrap">
                <span className="px-3 py-1.5 bg-[var(--primary-light)] text-[var(--primary)] rounded-full text-xs font-medium">#打工日常</span>
                <span className="px-3 py-1.5 bg-[var(--primary-light)] text-[var(--primary)] rounded-full text-xs font-medium">#职场故事</span>
              </div>
            </div>

            {/* 右侧互动栏 - 新设计 */}
            <div className="absolute right-4 bottom-32 flex flex-col items-center gap-6">
              <button className="flex flex-col items-center transition-transform hover:scale-110">
                <div className="w-12 h-12 rounded-full bg-[var(--primary-light)] flex items-center justify-center mb-1">
                  <span className="text-2xl">❤️</span>
                </div>
                <span className="text-xs text-[var(--text-secondary)] font-medium">{formatNumber(item.likes)}</span>
              </button>
              <button className="flex flex-col items-center transition-transform hover:scale-110">
                <div className="w-12 h-12 rounded-full bg-[var(--primary-light)] flex items-center justify-center mb-1">
                  <span className="text-2xl">💬</span>
                </div>
                <span className="text-xs text-[var(--text-secondary)] font-medium">{formatNumber(item.comments)}</span>
              </button>
              <button className="flex flex-col items-center transition-transform hover:scale-110">
                <div className="w-12 h-12 rounded-full bg-[var(--primary-light)] flex items-center justify-center mb-1">
                  <span className="text-2xl">↗️</span>
                </div>
                <span className="text-xs text-[var(--text-secondary)] font-medium">{formatNumber(item.shares)}</span>
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* 底部指示器 - 新设计 */}
      <div className="absolute bottom-16 left-1/2 -translate-x-1/2 flex gap-1.5 z-10">
        {contents.map((_, idx) => (
          <div
            key={idx}
            className={`h-2 rounded-full transition-all ${
              idx === currentIndex ? 'w-6 bg-[var(--primary)]' : 'w-2 bg-[var(--text-muted)]'
            }`}
          />
        ))}
      </div>
    </div>
  );
}