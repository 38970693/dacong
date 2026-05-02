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
    // TODO: 实现点赞功能
    console.log('Like post:', post.id);
  };

  return (
    <article className="bg-zinc-900 rounded-xl p-4 mb-3">
      {/* 来源标签 */}
      {post.source && (
        <div className="mb-2">
          <span className="text-xs text-orange-400 bg-orange-400/10 px-2 py-1 rounded">
            {post.source}
          </span>
        </div>
      )}

      {/* 标题 */}
      <h3 className="text-lg font-semibold text-white mb-2 line-clamp-2">
        {post.title}
      </h3>

      {/* 内容预览 */}
      {post.content && (
        <p className="text-sm text-zinc-400 mb-3 line-clamp-3">
          {post.content}
        </p>
      )}

      {/* 底部信息 */}
      <div className="flex items-center justify-between text-xs text-zinc-500">
        {/* 时间 */}
        <span>{formatTime(post.created_at)}</span>

        {/* 互动数据 */}
        <div className="flex items-center gap-4">
          <button className="flex items-center gap-1 hover:text-orange-400 transition-colors">
            <span>👁️</span>
            <span>{formatNumber(post.views)}</span>
          </button>
          <button
            onClick={handleLike}
            className="flex items-center gap-1 hover:text-red-400 transition-colors"
          >
            <span>❤️</span>
            <span>{formatNumber(post.likes)}</span>
          </button>
          <button className="flex items-center gap-1 hover:text-blue-400 transition-colors">
            <span>💬</span>
            <span>{formatNumber(post.comments_count)}</span>
          </button>
        </div>
      </div>

      {/* 来源链接 */}
      {post.source_url && (
        <a
          href={post.source_url}
          target="_blank"
          rel="noopener noreferrer"
          className="block mt-2 text-xs text-zinc-600 hover:text-orange-400 transition-colors"
        >
          阅读原文 →
        </a>
      )}
    </article>
  );
}