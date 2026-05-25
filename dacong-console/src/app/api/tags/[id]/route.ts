// 静态导出模式：排除此路由
export const dynamic = 'force-static';

// 静态导出模式需要：返回占位符，不预渲染任何静态页面
export async function generateStaticParams() {
  return [{ id: '__placeholder__' }];
}

import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

interface RouteParams {
  params: Promise<{ id: string }>;
}

// 删除标签
export async function DELETE(_request: NextRequest, { params }: RouteParams) {
  try {
    const { id } = await params;

    if (!id) {
      return NextResponse.json(
        { success: false, error: '标签 ID 不能为空' },
        { status: 400 }
      );
    }

    // 检查标签是否存在
    const { data: existing } = await supabase
      .from('tags')
      .select('id, name')
      .eq('id', id)
      .single();

    if (!existing) {
      return NextResponse.json(
        { success: false, error: '标签不存在' },
        { status: 404 }
      );
    }

    // 删除标签（关联的 post_tags 会通过级联删除）
    const { error } = await supabase
      .from('tags')
      .delete()
      .eq('id', id);

    if (error) throw error;

    return NextResponse.json({
      success: true,
      message: `标签 "${existing.name}" 已删除`
    });
  } catch (error) {
    console.error('Delete tag error:', error);
    return NextResponse.json(
      { success: false, error: '删除标签失败' },
      { status: 500 }
    );
  }
}

// 更新标签
export async function PATCH(request: NextRequest, { params }: RouteParams) {
  try {
    const { id } = await params;
    const body = await request.json();
    const { name, color } = body;

    if (!id) {
      return NextResponse.json(
        { success: false, error: '标签 ID 不能为空' },
        { status: 400 }
      );
    }

    // 构建更新对象
    const updates: Record<string, string> = {};

    if (name) {
      updates.name = name.trim();
      updates.slug = name
        .toLowerCase()
        .replace(/[^a-z0-9一-龥]/g, '-')
        .replace(/-+/g, '-')
        .replace(/^-|-$/g, '');
    }

    if (color) {
      updates.color = color;
    }

    if (Object.keys(updates).length === 0) {
      return NextResponse.json(
        { success: false, error: '没有需要更新的字段' },
        { status: 400 }
      );
    }

    const { data, error } = await supabase
      .from('tags')
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    return NextResponse.json({ success: true, data });
  } catch (error) {
    console.error('Update tag error:', error);
    return NextResponse.json(
      { success: false, error: '更新标签失败' },
      { status: 500 }
    );
  }
}