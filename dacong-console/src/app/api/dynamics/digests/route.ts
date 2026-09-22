export const dynamic = 'force-dynamic';

import { NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

export async function GET() {
  try {
    const { data, error } = await getSupabaseAdmin()
      .from('daily_digests')
      .select('id,digest_date,title,intro,item_count,published_at')
      .eq('status', 'published')
      .order('digest_date', { ascending: false })
      .limit(90);
    if (error) throw error;
    return NextResponse.json({ success: true, data: data ?? [] }, {
      headers: { 'Cache-Control': 'public, s-maxage=300, stale-while-revalidate=60' },
    });
  } catch (error) {
    console.error('[dynamics/digests]', error);
    return NextResponse.json({ success: false, data: [], error: '日报服务暂时不可用' }, { status: 503 });
  }
}
