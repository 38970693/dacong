export const dynamic = 'force-dynamic';

import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

export async function GET(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const { data, error } = await getSupabaseAdmin()
      .from('ai_news_items')
      .select('*,ai_news_sources(source,url,original_title,source_published_at,is_primary)')
      .eq('id', id)
      .eq('status', 'published')
      .maybeSingle();
    if (error) throw error;
    if (!data) return NextResponse.json({ success: false, error: '动态不存在' }, { status: 404 });
    return NextResponse.json({ success: true, data }, { headers: { 'Cache-Control': 'no-store' } });
  } catch (error) {
    console.error('[dynamics/news/detail]', error);
    return NextResponse.json({ success: false, error: 'AI 动态服务暂时不可用' }, { status: 503 });
  }
}
