import { formatDistanceToNow } from 'date-fns';
import { zhCN } from 'date-fns/locale';

interface PostCardProps {
  id: string;
  title: string;
  content: string | null;
  source: string | null;
  source_url: string | null;
  views: number;
  likes: number;
  comments_count: number;
  created_at: string;
}

function formatNumber(n: number): string {
  if (n >= 10000) return (n / 10000).toFixed(1) + 'w';
  if (n >= 1000) return (n / 1000).toFixed(1) + 'k';
  return n.toString();
}

function formatTime(dateStr: string): string {
  try {
    return formatDistanceToNow(new Date(dateStr), { addSuffix: true, locale: zhCN });
  } catch {
    return '刚刚';
  }
}

export function PostCard({ post }: { post: PostCardProps }) {
  const handleLike = async () => {
    console.log('Like post:', post.id);
  };

  return (
    <article className="bg-white rounded-2xl p-5 mb-4 border border-[var(--border)] card-hover shadow-sm">
      {/* 来源标签 */}
      {post.source && (
        <div className="mb-3">
          <span className="tag">
            {post.source}
          </span>
        </div>
      )}

      {/* 标题 */}
      <h3 className="text-lg font-bold text-[var(--foreground)] mb-2 line-clamp-2 leading-snug">
        {post.title}
      </h3>

      {/* 内容预览 */}
      {post.content && (
        <p className="text-sm text-[var(--text-secondary)] mb-4 line-clamp-2 leading-relaxed">
          {post.content}
        </p>
      )}

      {/* 底部信息栏 */}
      <div className="flex items-center justify-between pt-3 border-t border-[var(--border)]">
        {/* 时间 */}
        <span className="text-xs text-[var(--text-muted)]">{formatTime(post.created_at)}</span>

        {/* 互动数据 */}
        <div className="flex items-center gap-5">
          <button className="flex items-center gap-1.5 text-[var(--text-muted)] hover:text-[var(--primary)] transition-colors group">
            <svg className="w-4 h-4 group-hover:scale-110 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
              <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <span className="text-xs font-medium">{formatNumber(post.views)}</span>
          </button>
          <button
            onClick={handleLike}
            className="flex items-center gap-1.5 text-[var(--text-muted)] hover:text-[var(--gradient-pink)] transition-colors group"
          >
            <svg className="w-4 h-4 group-hover:scale-110 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z" />
            </svg>
            <span className="text-xs font-medium">{formatNumber(post.likes)}</span>
          </button>
          <button className="flex items-center gap-1.5 text-[var(--text-muted)] hover:text-[var(--primary)] transition-colors group">
            <svg className="w-4 h-4 group-hover:scale-110 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
            </svg>
            <span className="text-xs font-medium">{formatNumber(post.comments_count)}</span>
          </button>
        </div>
      </div>

      {/* 来源链接 */}
      {post.source_url && (
        <a
          href={post.source_url}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-1 mt-3 text-xs text-[var(--primary)] hover:underline font-medium"
        >
          阅读原文
          <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M13.5 6H5.25A2.25 2.25 0 003 8.25v10.5A2.25 2.25 0 005.25 21h10.5A2.25 2.25 0 0018 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25" />
          </svg>
        </a>
      )}
    </article>
  );
}
