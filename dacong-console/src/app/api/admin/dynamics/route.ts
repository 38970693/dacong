export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/admin-utils';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

export async function GET(request: NextRequest) {
  const auth = await requireAdmin(request);
  if (auth instanceof NextResponse) return auth;
  const status = request.nextUrl.searchParams.get('status') || 'quarantined';
  if (!['published', 'quarantined', 'withdrawn'].includes(status)) {
    return NextResponse.json({ success: false, error: '状态无效' }, { status: 400 });
  }
  const { data, error } = await getSupabaseAdmin()
    .from('ai_news_items')
    .select('id,title,category,source_tier,quality_score,status,published_at,ai_news_sources(source,url)')
    .eq('status', status)
    .order('created_at', { ascending: false })
    .limit(100);
  if (error) return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  return NextResponse.json({ success: true, data: data ?? [] });
}
