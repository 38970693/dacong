import { NextResponse } from 'next/server';
import { createClient as createServerClient } from '@/utils/supabase/server';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const type = searchParams.get('type') || 'hot'; // 'hot' | 'new'
  const limit = parseInt(searchParams.get('limit') || '50', 10);

  const supabase = await createServerClient();

  let query;

  if (type === 'hot') {
    // 综合热榜：按 score 排序（score 由 Worker 计算）
    query = supabase
      .from('trending_cache')
      .select(`
        rank,
        score,
        post:posts!inner(
          id, title, content, source, source_url, views, likes, comments_count, created_at
        )
      `)
      .eq('list_type', 'hot')
      .order('rank', { ascending: true })
      .limit(limit);
  } else {
    // 最新榜：按 created_at 排序
    query = supabase
      .from('posts')
      .select('id, title, content, source, source_url, views, likes, comments_count, created_at')
      .order('created_at', { ascending: false })
      .limit(limit);
  }

  const { data, error } = await query;

  if (error) {
    console.error('[API Error] GET /api/trending:', error);
    return NextResponse.json(
      { success: false, error: error.message },
      { status: 500 }
    );
  }

  let trending;
  if (type === 'hot') {
    // 处理 joined 数据
    trending = (data || []).map((item: Record<string, unknown>) => ({
      ...(item.post as Record<string, unknown>),
      score: item.score,
      rank: item.rank
    }));
  } else {
    // 新榜不需要额外字段
    trending = data || [];
  }

  return NextResponse.json({
    success: true,
    trending,
    meta: { type, limit }
  });
}