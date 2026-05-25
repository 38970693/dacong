// 静态导出模式：排除此路由
export const dynamic = 'force-static';

// 静态导出模式需要：返回占位符，不预渲染任何静态页面
export async function generateStaticParams() {
  return [{ id: '__placeholder__' }];
}

import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';
import { getCurrentUser } from '@/lib/auth-utils';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

let supabase: ReturnType<typeof createClient> | null = null;

function getSupabaseClient() {
  if (!supabase && supabaseKey) {
    supabase = createClient(supabaseUrl, supabaseKey);
  }
  return supabase;
}

// PATCH /api/comments/[id] - 编辑评论
export async function PATCH(
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

    if (!id) {
      return NextResponse.json(
        { success: false, error: 'Comment ID is required' },
        { status: 400 }
      );
    }

    // 获取请求体
    let body: { content?: string };
    try {
      body = await request.json();
    } catch {
      return NextResponse.json(
        { success: false, error: 'Invalid JSON body' },
        { status: 400 }
      );
    }

    // 验证内容
    const { content } = body;
    if (!content || typeof content !== 'string') {
      return NextResponse.json(
        { success: false, error: 'Content is required' },
        { status: 400 }
      );
    }

    if (content.length < 1 || content.length > 2000) {
      return NextResponse.json(
        { success: false, error: 'Content must be 1-2000 characters' },
        { status: 400 }
      );
    }

    // 获取当前用户
    const user = await getCurrentUser(request);

    // 检查评论是否存在并获取作者
    const { data: existingComment, error: findError } = await client
      .from('comments')
      .select('id, user_id')
      .eq('id', id)
      .single();

    if (findError || !existingComment) {
      return NextResponse.json(
        { success: false, error: 'Comment not found' },
        { status: 404 }
      );
    }

    // 权限检查：只有评论作者可以编辑
    if (user && (existingComment as { user_id: string }).user_id !== user.id) {
      return NextResponse.json(
        { success: false, error: 'You can only edit your own comments' },
        { status: 403 }
      );
    }

    // 更新评论
    const { data: updatedComment, error: updateError } = await client
      .from('comments')
      .update({
        content,
        updated_at: new Date().toISOString()
      } as never)
      .eq('id', id)
      .select('id, content, updated_at')
      .single();

    if (updateError) throw updateError;

    return NextResponse.json({
      success: true,
      data: updatedComment
    });
  } catch (error) {
    console.error('Comments API PATCH error:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to update comment' },
      { status: 500 }
    );
  }
}

// DELETE /api/comments/[id] - 删除评论
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

    if (!id) {
      return NextResponse.json(
        { success: false, error: 'Comment ID is required' },
        { status: 400 }
      );
    }

    // 获取当前用户
    const user = await getCurrentUser(request);

    // 检查评论是否存在并获取作者
    const { data: existingComment, error: findError } = await client
      .from('comments')
      .select('id, user_id')
      .eq('id', id)
      .single();

    if (findError || !existingComment) {
      return NextResponse.json(
        { success: false, error: 'Comment not found' },
        { status: 404 }
      );
    }

    // 权限检查：只有评论作者可以删除
    if (user && (existingComment as { user_id: string }).user_id !== user.id) {
      return NextResponse.json(
        { success: false, error: 'You can only delete your own comments' },
        { status: 403 }
      );
    }

    // 删除评论（ON DELETE CASCADE 会自动删除子评论）
    const { error: deleteError } = await client
      .from('comments')
      .delete()
      .eq('id', id);

    if (deleteError) throw deleteError;

    return NextResponse.json({
      success: true,
      data: { message: 'Comment deleted successfully' }
    });
  } catch (error) {
    console.error('Comments API DELETE error:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to delete comment' },
      { status: 500 }
    );
  }
}