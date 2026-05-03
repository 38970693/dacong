'use client';

const trendingTopics = [
  { rank: 1, title: 'Claude 3 发布', count: '12.3k' },
  { rank: 2, title: 'GPT-5 预测', count: '8.7k' },
  { rank: 3, title: 'Llama 3 开源', count: '6.2k' },
  { rank: 4, title: 'Gemini API', count: '4.1k' },
  { rank: 5, title: 'AI 编程大火', count: '3.5k' },
];

const hotModels = [
  { name: 'GPT-4 Turbo', score: 9.8, comments: '12k' },
  { name: 'Claude 3', score: 9.6, comments: '8k' },
  { name: 'Gemini Pro', score: 9.4, comments: '6k' },
];

export function RightSidebar() {
  return (
    <aside className="w-80 shrink-0 p-4 sticky top-16 h-[calc(100vh-64px)] overflow-y-auto hidden xl:block">
      {/* 热门话题 */}
      <div className="bg-white rounded-2xl border border-[var(--border)] p-5 mb-4">
        <h3 className="font-semibold text-[var(--foreground)] mb-4 flex items-center gap-2">
          <span>🔥</span>
          <span>热门话题</span>
        </h3>
        <div className="space-y-4">
          {trendingTopics.map((topic) => (
            <div key={topic.rank} className="flex items-start gap-3">
              <span
                className={`text-lg font-bold w-6 ${
                  topic.rank <= 2 ? 'text-[var(--primary)]' : 'text-[var(--text-muted)]'
                }`}
              >
                {topic.rank}
              </span>
              <div className="flex-1">
                <p className="text-sm font-medium text-[var(--foreground)]">{topic.title}</p>
                <p className="text-xs text-[var(--text-muted)]">{topic.count} 讨论</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* 热门模型 */}
      <div className="bg-white rounded-2xl border border-[var(--border)] p-5 mb-4">
        <h3 className="font-semibold text-[var(--foreground)] mb-4 flex items-center gap-2">
          <span>🏆</span>
          <span>热门模型</span>
        </h3>
        <div className="space-y-4">
          {hotModels.map((model, idx) => (
            <div key={model.name} className="flex items-start gap-3">
              <span
                className={`text-lg font-bold w-6 ${
                  idx === 0 ? 'text-[var(--primary)]' : 'text-[var(--text-muted)]'
                }`}
              >
                #
              </span>
              <div className="flex-1">
                <p className="text-sm font-medium text-[var(--foreground)]">{model.name}</p>
                <p className="text-xs text-[var(--text-muted)]">
                  评分 {model.score} · {model.comments} 评论
                </p>
              </div>
            </div>
          ))}
        </div>
        <button className="w-full mt-4 py-2 text-sm text-[var(--primary)] font-medium hover:bg-[var(--primary-light)] rounded-lg transition-colors">
          查看完整排行榜 →
        </button>
      </div>

      {/* 推荐关注 */}
      <div className="bg-white rounded-2xl border border-[var(--border)] p-5">
        <h3 className="font-semibold text-[var(--foreground)] mb-4 flex items-center gap-2">
          <span>👥</span>
          <span>推荐关注</span>
        </h3>
        <div className="space-y-4">
          {[
            { name: 'AI 前沿', avatar: '🤖', desc: '每日 AI 资讯' },
            { name: '技术大咖', avatar: '👨‍💻', desc: '分享技术干货' },
            { name: 'AI 研究员', avatar: '🔬', desc: '前沿技术分析' },
          ].map((user) => (
            <div key={user.name} className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-[var(--primary-light)] flex items-center justify-center text-xl">
                {user.avatar}
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-[var(--foreground)]">{user.name}</p>
                <p className="text-xs text-[var(--text-muted)]">{user.desc}</p>
              </div>
              <button className="px-3 py-1.5 text-xs font-medium text-[var(--primary)] border border-[var(--primary)] rounded-full hover:bg-[var(--primary)] hover:text-white transition-colors">
                关注
              </button>
            </div>
          ))}
        </div>
      </div>
    </aside>
  );
}