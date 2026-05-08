'use client';

import { useParams, useRouter } from 'next/navigation';
import { useEffect, useState, useCallback } from 'react';
import { createClient } from '@supabase/supabase-js';
import { TagsDisplay } from '@/components/TagsDisplay';
import { TagSelector } from '@/components/TagSelector';
import type { Tag, Post as PostType, Comment as CommentType } from '@/types/database';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

export default function PostDetailPage() {
  const params = useParams();
  const router = useRouter();
  const postId = params?.id as string;

  const [post, setPost] = useState<PostType | null>(null);
  const [postTags, setPostTags] = useState<Tag[]>([]);
  const [comments, setComments] = useState<CommentType[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [liked, setLiked] = useState(false);
  const [showTagSelector, setShowTagSelector] = useState(false);

  const fetchPost = useCallback(async (id: string) => {
    setLoading(true);
    setError(null);
    try {
      const { data, error: fetchError } = await supabase
        .from('posts')
        .select('id, raw_post_id, title, content, source, source_url, views, likes, comments_count, created_at, updated_at')
        .eq('id', id)
        .single();

      if (fetchError) throw fetchError;
      setPost(data);
    } catch (err) {
      console.error('Fetch post error:', err);
      setError('获取帖子失败');
      setPost({
        id,
        raw_post_id: null,
        title: '帖子详情加载失败',
        content: '请返回重试',
        source: 'System',
        source_url: '',
        views: 0,
        likes: 0,
        comments_count: 0,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchPostTags = useCallback(async (id: string) => {
    try {
      const { data } = await supabase
        .from('post_tags')
        .select(`
          id,
          tag_id,
          tags (
            id,
            name,
            slug,
            color,
            created_at
          )
        `)
        .eq('post_id', id);

      const tags = data?.map(pt => {
        const tag = pt.tags as unknown as Tag;
        return tag ? { ...tag, post_count: 0 } : null;
      }).filter((t): t is Tag => t !== null) || [];
      setPostTags(tags);
    } catch {
      setPostTags([]);
    }
  }, []);

  const fetchComments = useCallback(async (id: string) => {
    try {
      const { data } = await supabase
        .from('reviews')
        .select('id, target_type, target_id, user_id, content, parent_id, likes, created_at, updated_at, profiles(email)')
        .eq('post_id', id)
        .order('created_at', { ascending: false })
        .limit(20);
      const comments = data?.map(r => ({
        ...r,
        user_email: (r.profiles as any)?.email || 'Anonymous'
      })) || [];
      setComments(comments);
    } catch {
      setComments([]);
    }
  }, []);

  useEffect(() => {
    if (postId) {
      fetchPost(postId);
      fetchPostTags(postId);
      fetchComments(postId);
    }
  }, [postId, fetchPost, fetchPostTags, fetchComments]);

  const handleLike = useCallback(() => {
    if (!post) return;
    const newLiked = !liked;
    setLiked(newLiked);
    setPost({ ...post, likes: post.likes + (newLiked ? 1 : -1) });
  }, [post, liked]);

  const handleAddTag = useCallback(async (tag: Tag) => {
    if (!post) return;

    if (postTags.some(pt => pt.id === tag.id)) {
      return;
    }

    try {
      const { error: insertError } = await supabase
        .from('post_tags')
        .insert({ post_id: post.id, tag_id: tag.id })
        .select()
        .single();

      if (insertError) throw insertError;

      setPostTags(prev => [...prev, tag]);
      setShowTagSelector(false);
    } catch (err) {
      console.error('Add tag error:', err);
    }
  }, [post, postTags]);

  const handleRemoveTag = useCallback(async (tagId: string) => {
    if (!post) return;

    try {
      const { error: deleteError } = await supabase
        .from('post_tags')
        .delete()
        .eq('post_id', post.id)
        .eq('tag_id', tagId);

      if (deleteError) throw deleteError;

      setPostTags(prev => prev.filter(t => t.id !== tagId));
    } catch (err) {
      console.error('Remove tag error:', err);
    }
  }, [post]);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="w-8 h-8 border-2 border-[var(--primary)] border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  if (!post) {
    return (
      <div className="p-5 text-center">
        <p className="text-[var(--text-muted)]">帖子不存在</p>
        <button onClick={() => router.back()} className="mt-4 px-4 py-2 bg-[var(--primary)] text-white rounded-lg">
          返回
        </button>
      </div>
    );
  }

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
        {post.source && (
          <div className="mb-4">
            <span className="tag">{post.source}</span>
          </div>
        )}

        {/* 标题 */}
        <h1 className="text-2xl font-bold text-[var(--foreground)] mb-4 leading-snug">
          {post.title}
        </h1>

        {/* 标签展示 */}
        <div className="mb-4">
          <TagsDisplay
            tags={postTags}
            onRemove={handleRemoveTag}
            onAddClick={() => setShowTagSelector(true)}
          />
        </div>

        {/* 元信息 */}
        <div className="flex items-center gap-4 text-sm text-[var(--text-muted)] mb-6">
          <span>发布于 {new Date(post.created_at).toLocaleDateString('zh-CN')}</span>
          <span>•</span>
          <span>👁 {post.views.toLocaleString()}</span>
          <span>•</span>
          <span>❤️ {post.likes.toLocaleString()}</span>
        </div>

        {/* 内容 */}
        <div className="prose prose-sm max-w-none text-[var(--foreground)] leading-relaxed whitespace-pre-wrap">
          {post.content || '暂无内容'}
        </div>

        {/* 互动按钮 */}
        <div className="flex gap-4 mt-8 pt-6 border-t border-[var(--border)]">
          <button
            onClick={handleLike}
            className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-full font-medium btn-hover transition-colors ${
              liked ? 'bg-red-500 text-white' : 'bg-[var(--primary)] text-white'
            }`}
          >
            <svg className="w-5 h-5" fill={liked ? 'currentColor' : 'none'} viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12z" />
            </svg>
            <span>点赞 {post.likes}</span>
          </button>
          <button className="flex-1 flex items-center justify-center gap-2 py-3 bg-white border border-[var(--border)] text-[var(--foreground)] rounded-full font-medium hover:border-[var(--primary)] transition-colors">
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
            </svg>
            <span>评论 {post.comments_count}</span>
          </button>
        </div>
      </article>

      {/* 标签选择器弹窗 */}
      {showTagSelector && (
        <TagSelector
          selectedTags={postTags}
          onSelect={handleAddTag}
          onClose={() => setShowTagSelector(false)}
        />
      )}

      {/* 评论区域 */}
      <div className="border-t border-[var(--border)]">
        <div className="px-5 py-4">
          <h3 className="font-semibold text-[var(--foreground)] flex items-center gap-2">
            <span>💬</span>
            <span>评论 ({comments.length})</span>
          </h3>
        </div>

        {/* 评论列表 */}
        {comments.length === 0 ? (
          <div className="p-8 text-center text-[var(--text-muted)]">暂无评论</div>
        ) : (
          <div className="divide-y divide-[var(--border)]">
            {comments.map((comment) => (
              <div key={comment.id} className="p-5">
                <div className="flex items-start gap-3">
                  <div className="w-10 h-10 rounded-full bg-[var(--primary-light)] flex items-center justify-center text-xl shrink-0">
                    👤
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center justify-between mb-1">
                      <span className="font-semibold text-sm text-[var(--foreground)]">{comment.user_email}</span>
                      <span className="text-xs text-[var(--text-muted)]">
                        {new Date(comment.created_at).toLocaleDateString('zh-CN')}
                      </span>
                    </div>
                    <p className="text-sm text-[var(--text-secondary)] leading-relaxed">{comment.content}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}