import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

// 获取标签下的所有文章
export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const tagSlug = searchParams.get('slug');
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '20');
    const offset = (page - 1) * limit;

    if (!tagSlug) {
      return NextResponse.json(
        { success: false, error: 'slug 是必填的' },
        { status: 400 }
      );
    }

    // 获取标签信息
    const { data: tag, error: tagError } = await supabase
      .from('tags')
      .select('*')
      .eq('slug', tagSlug)
      .single();

    if (tagError || !tag) {
      return NextResponse.json(
        { success: false, error: '标签不存在' },
        { status: 404 }
      );
    }

    // 获取该标签下的所有文章 ID
    const { data: postTags, error: postTagsError } = await supabase
      .from('post_tags')
      .select('post_id')
      .eq('tag_id', tag.id);

    if (postTagsError) throw postTagsError;

    const postIds = postTags?.map(pt => pt.post_id) || [];

    if (postIds.length === 0) {
      return NextResponse.json({
        success: true,
        data: {
          tag,
          posts: [],
          total: 0,
          page,
          limit
        }
      });
    }

    // 获取文章列表
    const { data: posts, error: postsError, count } = await supabase
      .from('posts')
      .select('id, title, content, source, source_url, views, likes, comments_count, created_at', { count: 'exact' })
      .in('id', postIds)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (postsError) throw postsError;

    return NextResponse.json({
      success: true,
      data: {
        tag,
        posts: posts || [],
        total: count || 0,
        page,
        limit
      }
    });
  } catch (error) {
    console.error('Get tag posts error:', error);
    return NextResponse.json(
      { success: false, error: '获取标签文章失败' },
      { status: 500 }
    );
  }
}