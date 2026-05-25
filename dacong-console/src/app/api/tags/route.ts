// Static export mode: exclude from static generation
export const dynamic = 'force-static';

import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

// 生成 slug 的辅助函数
function generateSlug(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9一-龥]/g, '-')  // 中文保留，其他非字母数字转横线
    .replace(/-+/g, '-')  // 多个横线合并
    .replace(/^-|-$/g, '');  // 去除首尾横线
}

// 预设颜色列表
const TAG_COLORS = [
  '#3B82F6', '#10B981', '#EC4899', '#F59E0B',
  '#8B5CF6', '#6366F1', '#22C55E', '#EF4444',
  '#F97316', '#14B8A6', '#A855F7', '#E11D48'
];

function getRandomColor(): string {
  return TAG_COLORS[Math.floor(Math.random() * TAG_COLORS.length)];
}

export async function GET() {
  try {
    const { data, error } = await supabase
      .from('tags')
      .select('*')
      .order('post_count', { ascending: false });

    if (error) throw error;

    return NextResponse.json({ success: true, data });
  } catch (error) {
    console.error('Tags API error:', error);
    return NextResponse.json({ success: false, error: 'Failed to fetch tags' }, { status: 500 });
  }
}

// 创建标签
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name, color } = body;

    // 验证必填字段
    if (!name || typeof name !== 'string' || name.trim().length === 0) {
      return NextResponse.json(
        { success: false, error: '标签名称不能为空' },
        { status: 400 }
      );
    }

    const trimmedName = name.trim();
    const slug = generateSlug(trimmedName);

    // 检查是否已存在
    const { data: existing } = await supabase
      .from('tags')
      .select('id')
      .eq('slug', slug)
      .single();

    if (existing) {
      return NextResponse.json(
        { success: false, error: '标签已存在' },
        { status: 409 }
      );
    }

    // 创建标签
    const { data, error } = await supabase
      .from('tags')
      .insert({
        name: trimmedName,
        slug,
        color: color || getRandomColor(),
        post_count: 0
      })
      .select()
      .single();

    if (error) throw error;

    return NextResponse.json({ success: true, data });
  } catch (error) {
    console.error('Create tag error:', error);
    return NextResponse.json(
      { success: false, error: '创建标签失败' },
      { status: 500 }
    );
  }
}