'use client';

import { useParams } from 'next/navigation';
import { PostCard } from '@/components/PostCard';

export default function PostDetailPage() {
  const params = useParams();
  const postId = params?.id as string;

  const mockPost = {
    id: postId,
    title: 'Claude 3 发布：超越 GPT-4 的多模态 AI 助手',
    content: `Anthropic 刚刚发布了 Claude 3 系列模型，在多项基准测试中超越了 GPT-4，成为当前最强的 AI 助手。

**Claude 3 系列包含三个模型：**

- **Claude 3 Opus**：最智能的模型，在复杂任务上表现最佳
- **Claude 3 Sonnet**：平衡性能和速度，适合大多数场景
- **Claude 3 Haiku**：最快最轻量的模型，适合简单任务

**主要特点：**

1. 多模态理解：支持文本、图像、文档等输入
2. 更长上下文：支持 200K tokens 的上下文窗口
3. 更低幻觉率：在多项测试中表现优于 GPT-4
4. 更快的响应速度：比 Claude 2 快 2 倍

**使用建议：**

对于需要深度推理的任务（如代码生成、复杂分析），推荐使用 Claude 3 Opus。对于日常对话和简单任务，Claude 3 Haiku 是不错的选择，性价比更高。`,
    source: 'HackerNews',
    source_url: 'https://news.ycombinator.com',
    views: 12345,
    likes: 2345,
    comments_count: 567,
    created_at: new Date().toISOString(),
  };

  const mockComments = [
    {
      id: 'c1',
      author: 'AI 研究员',
      avatar: '🔬',
      content: '实测 Claude 3 Opus 的代码能力确实很强，特别是长代码的生成和解释。',
      time: '30分钟前',
      likes: 45,
    },
    {
      id: 'c2',
      author: '前端开发',
      avatar: '👨‍💻',
      content: 'Haiku 的速度太快了，几乎感觉不到延迟，而且免费额度很良心。',
      time: '1小时前',
      likes: 23,
    },
    {
      id: 'c3',
      author: '产品经理',
      avatar: '👩‍💼',
      content: '多模态能力很强，试了试图片理解，效果比预期好很多。',
      time: '2小时前',
      likes: 12,
    },
  ];

  return (
    <div>
      {/* 返回导航 */}
      <div className="sticky top-0 z-10 bg-white/95 backdrop-blur-sm px-5 py-4 border-b border-[var(--border)] flex items-center gap-4">
        <button
          className="w-10 h-10 rounded-full bg-[var(--background)] flex items-center justify-center hover:bg-[var(--primary-light)] transition-colors"
          onClick={() => window.history.back()}
        >
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </button>
        <h1 className="text-lg font-bold text-[var(--foreground)]">帖子详情</h1>
      </div>

      {/* 帖子内容 */}
      <article className="p-5">
        {/* 来源标签 */}
        {mockPost.source && (
          <div className="mb-4">
            <span className="tag">{mockPost.source}</span>
          </div>
        )}

        {/* 标题 */}
        <h1 className="text-2xl font-bold text-[var(--foreground)] mb-4 leading-snug">
          {mockPost.title}
        </h1>

        {/* 元信息 */}
        <div className="flex items-center gap-4 text-sm text-[var(--text-muted)] mb-6">
          <span>发布于 {new Date(mockPost.created_at).toLocaleDateString('zh-CN')}</span>
          <span>•</span>
          <span>👁 {mockPost.views.toLocaleString()}</span>
          <span>•</span>
          <span>❤️ {mockPost.likes.toLocaleString()}</span>
        </div>

        {/* 内容 */}
        <div className="prose prose-sm max-w-none text-[var(--foreground)] leading-relaxed whitespace-pre-wrap">
          {mockPost.content}
        </div>

        {/* 互动按钮 */}
        <div className="flex gap-4 mt-8 pt-6 border-t border-[var(--border)]">
          <button className="flex-1 flex items-center justify-center gap-2 py-3 bg-[var(--primary)] text-white rounded-full font-medium btn-hover">
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z" />
            </svg>
            <span>点赞 {mockPost.likes}</span>
          </button>
          <button className="flex-1 flex items-center justify-center gap-2 py-3 bg-white border border-[var(--border)] text-[var(--foreground)] rounded-full font-medium hover:border-[var(--primary)] transition-colors">
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
            </svg>
            <span>评论 {mockPost.comments_count}</span>
          </button>
        </div>
      </article>

      {/* 评论区域 */}
      <div className="border-t border-[var(--border)]">
        <div className="px-5 py-4">
          <h3 className="font-semibold text-[var(--foreground)] flex items-center gap-2">
            <span>💬</span>
            <span>评论 ({mockPost.comments_count})</span>
          </h3>
        </div>

        {/* 评论列表 */}
        <div className="divide-y divide-[var(--border)]">
          {mockComments.map((comment) => (
            <div key={comment.id} className="p-5">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 rounded-full bg-[var(--primary-light)] flex items-center justify-center text-xl shrink-0">
                  {comment.avatar}
                </div>
                <div className="flex-1">
                  <div className="flex items-center justify-between mb-1">
                    <span className="font-semibold text-sm text-[var(--foreground)]">{comment.author}</span>
                    <span className="text-xs text-[var(--text-muted)]">{comment.time}</span>
                  </div>
                  <p className="text-sm text-[var(--text-secondary)] leading-relaxed">{comment.content}</p>
                  <div className="flex items-center gap-4 mt-2">
                    <button className="flex items-center gap-1 text-xs text-[var(--text-muted)] hover:text-[var(--primary)]">
                      <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z" />
                      </svg>
                      {comment.likes}
                    </button>
                    <button className="text-xs text-[var(--text-muted)] hover:text-[var(--primary)]">回复</button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}