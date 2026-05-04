'use client';

import { useRouter } from 'next/navigation';

const messageTypes = [
  { id: 'notify', label: '通知', icon: 'M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9', unread: 3 },
  { id: 'comment', label: '评论', icon: 'M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z', unread: 12 },
  { id: 'like', label: '点赞', icon: 'M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z', unread: 89 },
  { id: 'follow', label: '关注', icon: 'M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z', unread: 5 },
];

const mockMessages = [
  {
    id: 1,
    type: 'comment',
    from: '前端小王',
    avatar: '👨‍💻',
    content: '这个方案确实不错，收藏了',
    time: '5分钟前',
  },
  {
    id: 2,
    type: 'like',
    from: '产品小红',
    avatar: '👩‍💼',
    content: '赞了你的帖子',
    time: '10分钟前',
  },
  {
    id: 3,
    type: 'notify',
    from: '系统',
    avatar: '🤖',
    content: '你的帖子被推荐到首页了',
    time: '1小时前',
  },
  {
    id: 4,
    type: 'follow',
    from: '算法工程师',
    avatar: '👨‍🔬',
    content: '关注了你',
    time: '2小时前',
  },
];

export function Messages() {
  const router = useRouter();

  const handleMessageTypeClick = (typeId: string) => {
    router.push(`/web/messages/${typeId}`);
  };

  return (
    <div className="h-full bg-[var(--background)] overflow-y-auto hide-scrollbar">
      {/* 顶部导航 */}
      <header className="sticky top-0 z-10 bg-white/95 backdrop-blur-lg px-5 py-4 border-b border-[var(--border)]">
        <h1 className="text-xl font-bold text-[var(--foreground)]">消息</h1>
      </header>

      {/* 消息类型网格 */}
      <div className="grid grid-cols-4 gap-3 p-5">
        {messageTypes.map((type) => (
          <div
            key={type.id}
            onClick={() => handleMessageTypeClick(type.id)}
            className="bg-white rounded-xl p-4 flex flex-col items-center card-hover border border-[var(--border)] shadow-sm cursor-pointer active:scale-95 transition-transform"
          >
            <div className="relative">
              <div className="w-12 h-12 rounded-xl bg-[var(--primary-light)] flex items-center justify-center mb-2">
                <svg className="w-6 h-6 text-[var(--primary)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d={type.icon} />
                </svg>
              </div>
              {type.unread > 0 && (
                <span className="absolute -top-1 -right-1 badge">
                  {type.unread > 99 ? '99+' : type.unread}
                </span>
              )}
            </div>
            <span className="text-xs font-medium text-[var(--text-secondary)]">{type.label}</span>
          </div>
        ))}
      </div>

      {/* 分隔标题 */}
      <div className="px-5 py-2 flex items-center gap-3">
        <span className="text-sm font-semibold text-[var(--foreground)]">最近消息</span>
        <span className="flex-1 h-px bg-[var(--border)]"></span>
      </div>

      {/* 消息列表 */}
      <div className="px-5 space-y-3 pb-20">
        {mockMessages.map((msg) => (
          <div
            key={msg.id}
            className="bg-white rounded-xl p-4 flex items-center gap-4 card-hover border border-[var(--border)] shadow-sm"
          >
            <div className="w-12 h-12 rounded-full bg-[var(--primary-light)] flex items-center justify-center text-2xl shrink-0">
              {msg.avatar}
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center justify-between mb-1">
                <span className="font-semibold text-sm text-[var(--foreground)]">{msg.from}</span>
                <span className="text-xs text-[var(--text-muted)]">{msg.time}</span>
              </div>
              <p className="text-sm text-[var(--text-secondary)] truncate">{msg.content}</p>
            </div>
            {/* 消息类型图标 */}
            <div className="w-8 h-8 rounded-full bg-[var(--primary-light)] flex items-center justify-center shrink-0">
              {msg.type === 'comment' && <span className="text-sm">💬</span>}
              {msg.type === 'like' && <span className="text-sm">❤️</span>}
              {msg.type === 'notify' && <span className="text-sm">🔔</span>}
              {msg.type === 'follow' && <span className="text-sm">➕</span>}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}