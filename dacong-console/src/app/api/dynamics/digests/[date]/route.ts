export const dynamic = 'force-dynamic';

import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

export async function GET(_request: Request, { params }: { params: Promise<{ date: string }> }) {
  try {
    const { date } = await params;
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      return NextResponse.json({ success: false, error: '日期格式无效' }, { status: 400 });
    }
    const supabase = getSupabaseAdmin();
    const { data: digest, error } = await supabase
      .from('daily_digests')
      .select('id,digest_date,title,intro,item_count,published_at')
      .eq('digest_date', date)
      .eq('status', 'published')
      .maybeSingle();
    if (error) throw error;
    if (!digest) return NextResponse.json({ success: false, error: '日报不存在' }, { status: 404 });
    const { data: items, error: itemsError } = await supabase
      .from('daily_digest_items')
      .select('rank,category,ai_news_items!inner(*,ai_news_sources(source,url,source_published_at,is_primary))')
      .eq('digest_id', digest.id)
      .eq('ai_news_items.status', 'published')
      .order('rank');
    if (itemsError) throw itemsError;
    return NextResponse.json({ success: true, data: { ...digest, items: items ?? [] } });
  } catch (error) {
    console.error('[dynamics/digests/detail]', error);
    return NextResponse.json({ success: false, error: '日报服务暂时不可用' }, { status: 503 });
  }
}
