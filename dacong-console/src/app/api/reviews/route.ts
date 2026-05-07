import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';
import type { ReviewArticle, ReviewArticleInput } from '@/types/database';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://prszkdbdgffbdqclbgol.supabase.co';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

// 创建 slug 的辅助函数
function createSlug(title: string): string {
  return title
    .toLowerCase()
    .replace(/[^a-z0-9一-龥]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .substring(0, 100);
}

// GET /api/reviews - 获取评测文章列表
export async function GET(request: NextRequest) {
  try {
    const supabase = createClient(supabaseUrl, supabaseKey);
    const searchParams = request.nextUrl.searchParams;
    const limit = parseInt(searchParams.get('limit') || '20');
    const offset = parseInt(searchParams.get('offset') || '0');
    const published = searchParams.get('published');

    let query = supabase
      .from('reviews')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    // 如果没有指定 published 参数，只返回已发布的
    if (published === null) {
      query = query.eq('published', true);
    } else if (published === 'all') {
      // 返回所有（包括草稿）
    } else {
      query = query.eq('published', published === 'true');
    }

    const { data, error, count } = await query;

    if (error) throw error;

    return NextResponse.json({
      success: true,
      data: data as ReviewArticle[],
      meta: {
        total: count || 0,
        limit,
        offset,
      },
    });
  } catch (error) {
    console.error('Reviews API GET error:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to fetch reviews' },
      { status: 500 }
    );
  }
}

// POST /api/reviews - 创建评测文章
export async function POST(request: NextRequest) {
  try {
    const supabase = createClient(supabaseUrl, supabaseKey);
    const body: ReviewArticleInput = await request.json();

    // 验证必填字段
    if (!body.title?.trim()) {
      return NextResponse.json(
        { success: false, error: 'Title is required' },
        { status: 400 }
      );
    }

    // 生成 slug
    const slug = body.slug || createSlug(body.title);

    // 验证 slug 唯一性
    const { data: existing } = await supabase
      .from('reviews')
      .select('id')
      .eq('slug', slug)
      .single();

    if (existing) {
      return NextResponse.json(
        { success: false, error: 'Slug already exists' },
        { status: 400 }
      );
    }

    const now = new Date().toISOString();
    const newReview = {
      title: body.title.trim(),
      slug,
      content: body.content || '',
      summary: body.summary || null,
      author_name: body.author_name || '匿名用户',
      author_avatar: body.author_avatar || null,
      cover_image: body.cover_image || null,
      tags: body.tags || [],
      tools_mentioned: body.tools_mentioned || [],
      views: 0,
      likes: 0,
      published: body.published ?? false,
      published_at: body.published ? now : null,
      created_at: now,
      updated_at: now,
    };

    const { data, error } = await supabase
      .from('reviews')
      .insert([newReview])
      .select()
      .single();

    if (error) throw error;

    return NextResponse.json({
      success: true,
      data: data as ReviewArticle,
    });
  } catch (error) {
    console.error('Reviews API POST error:', error);
    return NextResponse.json(
      { success: false, error: 'Failed to create review' },
      { status: 500 }
    );
  }
}