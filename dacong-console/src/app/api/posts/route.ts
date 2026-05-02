import { NextResponse } from 'next/server';
import { createClient as createServerClient } from '@/utils/supabase/server';

const DEFAULT_LIMIT = 20;

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const cursor = searchParams.get('cursor');
  const limit = parseInt(searchParams.get('limit') || String(DEFAULT_LIMIT), 10);

  const supabase = await createServerClient();

  let query = supabase
    .from('posts')
    .select('id, title, content, source, source_url, views, likes, comments_count, created_at, updated_at', {
      count: 'exact'
    })
    .eq('status', 'approved')
    .order('created_at', { ascending: false })
    .limit(limit);

  // Cursor 分页：使用 created_at 作为游标
  if (cursor) {
    // cursor 格式：timestamp_id (例如: "2024-01-01T00:00:00Z_abc123")
    const [timestamp, id] = cursor.split('_');
    if (timestamp && id) {
      query = query
        .lt('created_at', timestamp)
        .lt('id', id);
    }
  }

  const { data: posts, error, count } = await query;

  if (error) {
    console.error('[API Error] GET /api/posts:', error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }

  // 生成下一个 cursor
  let nextCursor: string | null = null;
  if (posts && posts.length === limit) {
    const lastPost = posts[posts.length - 1];
    nextCursor = `${lastPost.created_at}_${lastPost.id}`;
  }

  return NextResponse.json({
    success: true,
    posts: posts || [],
    next_cursor: nextCursor,
    meta: {
      total: count || 0,
      limit,
      hasMore: !!nextCursor
    }
  });
}