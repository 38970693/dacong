// Static export mode: exclude from static generation
export const dynamic = 'force-static';

// Static export requires: return placeholder, do not pre-render any static pages
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

// 删除文章标签关联
export async function DELETE(_request: NextRequest, { params }: RouteParams) {
  try {
    const { id } = await params;

    if (!id) {
      return NextResponse.json(
        { success: false, error: '关联 ID 不能为空' },
        { status: 400 }
      );
    }

    const { error } = await supabase
      .from('post_tags')
      .delete()
      .eq('id', id);

    if (error) throw error;

    return NextResponse.json({ success: true, message: '标签已从文章移除' });
  } catch (error) {
    console.error('Remove post tag error:', error);
    return NextResponse.json(
      { success: false, error: '移除标签失败' },
      { status: 500 }
    );
  }
}