'use client';

export default function Profile() {
  const user = {
    name: '打工聪',
    avatar: '🧑‍💼',
    bio: '一个热爱编程的普通程序员',
    fans: 1234,
    follow: 567,
    likes: 8901,
  };

  const myPosts = [
    { id: 1, title: '我的第一个帖子', likes: 100, comments: 20 },
    { id: 2, title: '今天学到的新技术', likes: 56, comments: 8 },
  ];

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
          <button className="flex-1 py-2 bg-[#ff6b35] rounded-lg font-medium text-sm">
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
      </div>
    </div>
  );
}
