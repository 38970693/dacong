'use client';

import { useUserStore } from '@/stores';

interface ProfileProps {
  onLogin?: () => void;
}

export default function Profile({ onLogin }: ProfileProps) {
  const { isAuthenticated, userId, role } = useUserStore();

  // 未登录状态
  if (!isAuthenticated) {
    return (
      <div className="h-full bg-black text-white flex flex-col items-center justify-center p-6">
        <div className="text-6xl mb-6">👤</div>
        <h2 className="text-xl font-bold mb-2">登录 / 注册</h2>
        <p className="text-sm text-zinc-500 mb-6 text-center">
          登录后可以点赞、评论，关注更多精彩内容
        </p>

        <button
          onClick={onLogin}
          className="w-full max-w-xs py-3 bg-orange-500 rounded-lg font-medium hover:bg-orange-600 transition-colors"
        >
          登录
        </button>

        <div className="mt-4 text-xs text-zinc-600">
          登录即表示同意用户协议和隐私政策
        </div>
      </div>
    );
  }

  // 已登录状态（mock 数据，后续连接真实用户数据）
  const user = {
    name: '用户',
    avatar: '🧑‍💼',
    bio: '正在享受 DaCong 的精彩内容',
    fans: 0,
    follow: 0,
    likes: 0,
  };

  const myPosts: { id: string; title: string; likes: number; comments: number }[] = [];

  return (
    <div className="h-full bg-black text-white overflow-y-auto hide-scrollbar pb-16">
      {/* 个人信息区 */}
      <div className="bg-gradient-to-b from-zinc-900 to-black p-6 pt-12">
        <div className="flex items-center gap-4">
          <div className="w-20 h-20 rounded-full bg-zinc-800 flex items-center justify-center text-4xl">
            {user.avatar}
          </div>
          <div>
            <h1 className="text-2xl font-bold">{user.name}</h1>
            <p className="text-sm text-white/60 mt-1">{user.bio}</p>
          </div>
        </div>

        {/* 数据统计 */}
        <div className="flex justify-around mt-6 py-4 border-t border-b border-white/10">
          <div className="text-center">
            <p className="text-xl font-bold">{user.fans}</p>
            <p className="text-xs text-white/50">粉丝</p>
          </div>
          <div className="text-center">
            <p className="text-xl font-bold">{user.follow}</p>
            <p className="text-xs text-white/50">关注</p>
          </div>
          <div className="text-center">
            <p className="text-xl font-bold">{user.likes}</p>
            <p className="text-xs text-white/50">获赞</p>
          </div>
        </div>

        {/* 操作按钮 */}
        <div className="flex gap-3 mt-4">
          <button className="flex-1 py-2 bg-zinc-800 rounded-lg font-medium text-sm hover:bg-zinc-700">
            编辑资料
          </button>
          <button className="px-4 py-2 bg-zinc-800 rounded-lg text-sm">
            ⚙️
          </button>
        </div>
      </div>

      {/* 我的发布 */}
      <div className="p-4">
        <h2 className="font-semibold mb-3">我的发布</h2>
        {myPosts.length === 0 ? (
          <div className="text-center text-zinc-500 py-8">
            <p>还没有发布内容</p>
          </div>
        ) : (
          <div className="space-y-3">
            {myPosts.map((post) => (
              <div key={post.id} className="bg-zinc-900 rounded-lg p-3">
                <p className="font-medium text-sm">{post.title}</p>
                <div className="flex items-center gap-4 mt-2 text-xs text-white/50">
                  <span>❤️ {post.likes}</span>
                  <span>💬 {post.comments}</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}