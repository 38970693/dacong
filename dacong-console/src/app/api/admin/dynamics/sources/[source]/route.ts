export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/admin-utils';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

export async function PATCH(request: NextRequest, { params }: { params: Promise<{ source: string }> }) {
  const auth = await requireAdmin(request);
  if (auth instanceof NextResponse) return auth;
  const { source } = await params;
  const body = await request.json();
  const update: Record<string, unknown> = { updated_at: new Date().toISOString() };
  if (typeof body.enabled === 'boolean') update.enabled = body.enabled;
  if (['official', 'professional', 'community'].includes(body.tier)) update.tier = body.tier;
  const { data, error } = await getSupabaseAdmin()
    .from('ai_source_settings')
    .update(update)
    .eq('source', decodeURIComponent(source))
    .select('*')
    .maybeSingle();
  if (error) return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  if (!data) return NextResponse.json({ success: false, error: '来源不存在' }, { status: 404 });
  return NextResponse.json({ success: true, data });
}
