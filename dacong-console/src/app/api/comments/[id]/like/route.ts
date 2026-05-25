// 静态导出模式：排除此路由
export const dynamic = 'force-static';

// 静态导出模式需要：返回占位符，不预渲染任何静态页面
export async function generateStaticParams() {
  return [{ id: '__placeholder__' }];
}

import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

let supabase: ReturnType<typeof createClient> | null = null;

function getSupabaseClient() {
  if (!supabase && supabaseKey) {
    supabase = createClient(supabaseUrl, supabaseKey);
  }
  return supabase;
}

// POST /api/comments/[id]/like - 点赞评论
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const client = getSupabaseClient();
    if (!client) {
      return NextResponse.json(
        { success: false, error: 'Database not configured' },
        { status: 500 }
      );
    }

    const { id } = await params;
    const body = await request.json().catch(() => ({}));
    const userId = body.user_id || 'anonymous';

    if (!id) {
      return NextResponse.json(
        { success: false, error: 'Comment ID is required' },
        { status: 400 }
      );
    }

    // 检查评论是否存在
    const { data: comment, error: findError } = await client
      .from('comments')
      .select('id, likes')
      .eq('id', id)
      .single();

    if (findError || !comment) {
      return NextResponse.json(
        { success: false, error: 'Comment not found' },
        { status: 404 }
      );
    }

    const currentLikes = (comment as { id: string; likes: number | null }).likes || 0;

    // 使用 upsert 添加点赞记录
    const { error: upsertError } = await client
      .from('likes')
      .upsert(
        {
          user_id: userId,
          target_type: 'comment',
          target_id: id,
          created_at: new Date().toISOString(),
        } as never,
        { onConflict: 'user_id,target_type,target_id' }
      );

    if (upsertError) throw upsertError;

    // 增加评论的点赞数
    const { error: updateError } = await client
      .from('comments')
      .update({ likes: currentLikes + 1 } as never)
      .eq('id', id);

    if (updateError) throw updateError;

    return NextResponse.json({
      success: true,
      data: { likes: currentLikes + 1 }
    });
  } catch (error) {
    console.error('Comments like API error:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to like comment' },
      { status: 500 }
    );
  }
}

// DELETE /api/comments/[id]/like - 取消点赞
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const client = getSupabaseClient();
    if (!client) {
      return NextResponse.json(
        { success: false, error: 'Database not configured' },
        { status: 500 }
      );
    }

    const { id } = await params;
    const body = await request.json().catch(() => ({}));
    const userId = body.user_id || 'anonymous';

    if (!id) {
      return NextResponse.json(
        { success: false, error: 'Comment ID is required' },
        { status: 400 }
      );
    }

    // 检查评论是否存在并获取当前点赞数
    const { data: comment, error: findError } = await client
      .from('comments')
      .select('id, likes')
      .eq('id', id)
      .single();

    if (findError || !comment) {
      return NextResponse.json(
        { success: false, error: 'Comment not found' },
        { status: 404 }
      );
    }

    const currentLikes = (comment as { id: string; likes: number | null }).likes || 0;

    // 删除点赞记录
    const { error: deleteError } = await client
      .from('likes')
      .delete()
      .eq('user_id', userId)
      .eq('target_type', 'comment')
      .eq('target_id', id);

    if (deleteError) throw deleteError;

    // 减少评论的点赞数（确保不小于 0）
    const newLikes = Math.max(currentLikes - 1, 0);
    const { error: updateError } = await client
      .from('comments')
      .update({ likes: newLikes } as never)
      .eq('id', id);

    if (updateError) throw updateError;

    return NextResponse.json({
      success: true,
      data: { likes: newLikes }
    });
  } catch (error) {
    console.error('Comments unlike API error:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to unlike comment' },
      { status: 500 }
    );
  }
}