export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/admin-utils';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string; action: string }> }) {
  const auth = await requireAdmin(request);
  if (auth instanceof NextResponse) return auth;
  const { id, action } = await params;
  const status = action === 'withdraw' ? 'withdrawn' : action === 'restore' ? 'published' : null;
  if (!status) return NextResponse.json({ success: false, error: '操作无效' }, { status: 400 });
  const { data, error } = await getSupabaseAdmin()
    .from('ai_news_items')
    .update({ status, updated_at: new Date().toISOString() })
    .eq('id', id)
    .select('id,status')
    .maybeSingle();
  if (error) return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  if (!data) return NextResponse.json({ success: false, error: '动态不存在' }, { status: 404 });
  return NextResponse.json({ success: true, data });
}
