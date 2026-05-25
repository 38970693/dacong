// 静态导出模式：排除此路由
export const dynamic = 'force-static';

// 静态导出模式需要：返回占位符，不预渲染任何静态页面
export async function generateStaticParams() {
  return [{ id: '__placeholder__' }];
}

import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';
import type { ReviewArticle, ReviewArticleUpdate } from '@/types/database';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

// 生成 slug 的辅助函数
function createSlug(title: string): string {
  return title
    .toLowerCase()
    .replace(/[^a-z0-9一-龥]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .substring(0, 100);
}

// GET /api/reviews/[id] - 获取单篇评测文章（通过 id 或 slug）
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 判断是 id 还是 slug
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);

    let query;
    if (isUuid) {
      query = supabase.from('reviews').select('*').eq('id', id);
    } else {
      query = supabase.from('reviews').select('*').eq('slug', id);
    }

    const { data, error } = await query.single();

    if (error) {
      return NextResponse.json(
        { success: false, error: 'Review not found' },
        { status: 404 }
      );
    }

    // 增加浏览量
    await supabase
      .from('reviews')
      .update({ views: (data.views || 0) + 1 })
      .eq('id', data.id);

    return NextResponse.json({
      success: true,
      data: { ...data, views: (data.views || 0) + 1 } as ReviewArticle,
    });
  } catch (error) {
    console.error('Review API GET error:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to fetch review' },
      { status: 500 }
    );
  }
}

// PUT /api/reviews/[id] - 更新评测文章
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const supabase = createClient(supabaseUrl, supabaseKey);
    const body: ReviewArticleUpdate = await request.json();

    // 检查文章是否存在
    const { data: existing } = await supabase
      .from('reviews')
      .select('id, published')
      .eq('id', id)
      .single();

    if (!existing) {
      return NextResponse.json(
        { success: false, error: 'Review not found' },
        { status: 404 }
      );
    }

    const now = new Date().toISOString();
    const updateData: Record<string, unknown> = {
      updated_at: now,
    };

    // 处理可更新字段
    if (body.title !== undefined) {
      updateData.title = body.title.trim();
      // 如果没有提供 slug，自动生成
      if (!body.slug) {
        updateData.slug = createSlug(body.title);
      }
    }
    if (body.slug !== undefined) {
      updateData.slug = body.slug;
    }
    if (body.content !== undefined) {
      updateData.content = body.content;
    }
    if (body.summary !== undefined) {
      updateData.summary = body.summary;
    }
    if (body.author_name !== undefined) {
      updateData.author_name = body.author_name;
    }
    if (body.author_avatar !== undefined) {
      updateData.author_avatar = body.author_avatar;
    }
    if (body.cover_image !== undefined) {
      updateData.cover_image = body.cover_image;
    }
    if (body.tags !== undefined) {
      updateData.tags = body.tags;
    }
    if (body.tools_mentioned !== undefined) {
      updateData.tools_mentioned = body.tools_mentioned;
    }
    if (body.published !== undefined) {
      updateData.published = body.published;
      // 设置发布时间
      if (body.published && !existing.published) {
        updateData.published_at = now;
      }
    }

    const { data, error } = await supabase
      .from('reviews')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    return NextResponse.json({
      success: true,
      data: data as ReviewArticle,
    });
  } catch (error) {
    console.error('Review API PUT error:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to update review' },
      { status: 500 }
    );
  }
}

// DELETE /api/reviews/[id] - 删除评测文章
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 检查文章是否存在
    const { data: existing } = await supabase
      .from('reviews')
      .select('id')
      .eq('id', id)
      .single();

    if (!existing) {
      return NextResponse.json(
        { success: false, error: 'Review not found' },
        { status: 404 }
      );
    }

    const { error } = await supabase
      .from('reviews')
      .delete()
      .eq('id', id);

    if (error) throw error;

    return NextResponse.json({
      success: true,
      data: { id },
    });
  } catch (error) {
    console.error('Review API DELETE error:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to delete review' },
      { status: 500 }
    );
  }
}
