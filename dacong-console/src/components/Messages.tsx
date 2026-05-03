'use client';

const messageTypes = [
  { id: 'notify', label: '通知', icon: '🔔', unread: 3 },
  { id: 'comment', label: '评论', icon: '💬', unread: 12 },
  { id: 'like', label: '点赞', icon: '❤️', unread: 89 },
  { id: 'follow', label: '关注', icon: '➕', unread: 5 },
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
];

export function Messages() {
  return (
    <div className="h-full bg-black text-white overflow-y-auto hide-scrollbar pb-16">
      <header className="sticky top-0 z-10 bg-black/95 backdrop-blur-sm px-4 py-3 border-b border-white/10">
        <h1 className="text-xl font-bold">消息</h1>
      </header>

      {/* 消息类型 */}
      <div className="grid grid-cols-4 gap-2 p-4">
        {messageTypes.map((type) => (
          <div
            key={type.id}
            className="bg-zinc-900 rounded-lg p-3 flex flex-col items-center"
          >
            <div className="relative">
              <span className="text-2xl">{type.icon}</span>
              {type.unread > 0 && (
                <span className="absolute -top-1 -right-1 w-4 h-4 bg-red-500 rounded-full text-[10px] flex items-center justify-center">
                  {type.unread > 9 ? '9+' : type.unread}
                </span>
              )}
            </div>
            <span className="text-xs mt-1.5 text-white/70">{type.label}</span>
          </div>
        ))}
      </div>

      {/* 消息列表 */}
      <div className="px-4 space-y-2">
        {mockMessages.map((msg) => (
          <div
            key={msg.id}
            className="bg-zinc-900 rounded-lg p-3 flex items-center gap-3"
          >
            <div className="w-12 h-12 rounded-full bg-zinc-800 flex items-center justify-center text-xl">
              {msg.avatar}
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center justify-between">
                <span className="font-medium text-sm">{msg.from}</span>
                <span className="text-xs text-white/40">{msg.time}</span>
              </div>
              <p className="text-sm text-white/60 truncate">{msg.content}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
