import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

// 为文章添加标签
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { post_id, tag_id } = body;

    if (!post_id || !tag_id) {
      return NextResponse.json(
        { success: false, error: 'post_id 和 tag_id 都是必填的' },
        { status: 400 }
      );
    }

    // 检查是否已存在关联
    const { data: existing } = await supabase
      .from('post_tags')
      .select('id')
      .eq('post_id', post_id)
      .eq('tag_id', tag_id)
      .single();

    if (existing) {
      return NextResponse.json(
        { success: false, error: '该标签已添加到此文章' },
        { status: 409 }
      );
    }

    // 创建关联
    const { data, error } = await supabase
      .from('post_tags')
      .insert({ post_id, tag_id })
      .select()
      .single();

    if (error) throw error;

    return NextResponse.json({ success: true, data });
  } catch (error) {
    console.error('Add post tag error:', error);
    return NextResponse.json(
      { success: false, error: '添加标签失败' },
      { status: 500 }
    );
  }
}

// 获取文章的所有标签
export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const postId = searchParams.get('post_id');

    if (!postId) {
      return NextResponse.json(
        { success: false, error: 'post_id 是必填的' },
        { status: 400 }
      );
    }

    const { data, error } = await supabase
      .from('post_tags')
      .select(`
        id,
        tag_id,
        created_at,
        tags (
          id,
          name,
          slug,
          color
        )
      `)
      .eq('post_id', postId);

    if (error) throw error;

    // 提取标签信息
    const tags = data?.map(pt => pt.tags).filter(Boolean) || [];

    return NextResponse.json({ success: true, data: tags });
  } catch (error) {
    console.error('Get post tags error:', error);
    return NextResponse.json(
      { success: false, error: '获取标签失败' },
      { status: 500 }
    );
  }
}