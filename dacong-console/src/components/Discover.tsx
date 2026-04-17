'use client';

import { useState } from 'react';

const hotTopics = [
  { id: 1, title: '今天又被甲方折磨了', heat: 99, icon: '🔥' },
  { id: 2, title: '程序员相亲对象都是谁', heat: 95, icon: '💕' },
  { id: 3, title: '月薪3万的生活是什么样的', heat: 88, icon: '💰' },
  { id: 4, title: '老板画的饼你吃过几个', heat: 85, icon: '🥧' },
];

const categories = [
  { id: 'tech', name: '技术交流', icon: '💻', desc: '代码、架构、工具' },
  { id: 'career', name: '职场话题', icon: '💼', desc: '晋升、加薪、面试' },
  { id: 'life', name: '生活日常', icon: '🌴', desc: '美食、旅行、爱好' },
  { id: 'emotion', name: '情感树洞', icon: '🌲', desc: '倾诉、吐槽、迷茫' },
  { id: 'investment', name: '投资理财', icon: '📈', desc: '股票、基金、房产' },
  { id: 'tools', name: '效率工具', icon: '🛠️', desc: '好物、软件推荐' },
];

const posts = [
  {
    id: 1,
    author: '前端小明',
    avatar: '👨‍💻',
    category: 'tech',
    title: 'React 19终于来了，有什么新特性？',
    content: '听说有新的编译器优化，性能提升明显...',
    likes: 234,
    comments: 45,
    time: '10分钟前',
  },
  {
    id: 2,
    author: '产品小红',
    avatar: '👩‍产品',
    category: 'career',
    title: '35岁程序员真的会被优化吗',
    content: '在互联网寒冬下，这个话题越来越现实了',
    likes: 567,
    comments: 123,
    time: '30分钟前',
  },
];

export default function Discover() {
  const [activeCategory, setActiveCategory] = useState('tech');

  return (
    <div className="h-full bg-black text-white overflow-y-auto hide-scrollbar pb-16">
      {/* 顶部标题 */}
      <header className="sticky top-0 z-10 bg-black/95 backdrop-blur-sm px-4 py-3 border-b border-white/10">
        <h1 className="text-xl font-bold">发现</h1>
      </header>

      {/* 热搜榜 */}
      <section className="p-4">
        <div className="flex items-center justify-between mb-3">
          <h2 className="font-semibold text-white/90">🔥 热议榜</h2>
          <span className="text-xs text-white/40">更多 &gt;</span>
        </div>
        <div className="grid grid-cols-2 gap-3">
          {hotTopics.map((topic, idx) => (
            <div
              key={topic.id}
              className="bg-zinc-900 rounded-lg p-3 flex items-start gap-2"
            >
              <span className={`text-lg ${idx < 2 ? 'text-[#ff6b35]' : 'text-white/60'}`}>
                {idx + 1}
              </span>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium truncate">{topic.title}</p>
                <p className="text-xs text-white/40 mt-0.5">{topic.icon} {topic.heat}万热度</p>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* 分类导航 */}
      <section className="px-4 mb-4">
        <div className="flex gap-2 overflow-x-auto hide-scrollbar pb-2">
          {categories.map((cat) => (
            <button
              key={cat.id}
              onClick={() => setActiveCategory(cat.id)}
              className={`flex-shrink-0 px-4 py-2 rounded-full text-sm font-medium transition-colors ${
                activeCategory === cat.id
                  ? 'bg-[#ff6b35] text-white'
                  : 'bg-zinc-800 text-white/70'
              }`}
            >
              {cat.icon} {cat.name}
            </button>
          ))}
        </div>
      </section>

      {/* 分类描述 */}
      <section className="px-4 mb-4">
        <div className="bg-zinc-900/50 rounded-lg p-3 flex items-center gap-3">
          <span className="text-2xl">{categories.find(c => c.id === activeCategory)?.icon}</span>
          <div>
            <p className="font-medium">{categories.find(c => c.id === activeCategory)?.name}</p>
            <p className="text-xs text-white/50">{categories.find(c => c.id === activeCategory)?.desc}</p>
          </div>
        </div>
      </section>

      {/* 帖子列表 */}
      <section className="px-4 space-y-3">
        {posts
          .filter(p => p.category === activeCategory || activeCategory === 'tech')
          .map((post) => (
            <div key={post.id} className="bg-zinc-900 rounded-lg p-4">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 rounded-full bg-zinc-800 flex items-center justify-center">
                  {post.avatar}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-sm">{post.author}</span>
                    <span className="text-xs text-white/40">{post.time}</span>
                  </div>
                  <h3 className="font-semibold mt-1 mb-1">{post.title}</h3>
                  <p className="text-sm text-white/70 line-clamp-2">{post.content}</p>
                  <div className="flex items-center gap-4 mt-3 text-xs text-white/50">
                    <span>❤️ {post.likes}</span>
                    <span>💬 {post.comments}</span>
                  </div>
                </div>
              </div>
            </div>
          ))}
      </section>

      {/* 底部留白 */}
      <div className="h-4" />
    </div>
  );
}
