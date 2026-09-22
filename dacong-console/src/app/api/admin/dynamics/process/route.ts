export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import { requireAdmin } from '@/lib/admin-utils';
import { getSupabaseAdmin } from '@/lib/supabase-admin';

export async function POST(request: NextRequest) {
  const auth = await requireAdmin(request);
  if (auth instanceof NextResponse) return auth;

  const { data, error } = await getSupabaseAdmin().functions.invoke('process-ai-news', {
    body: {},
  });
  if (error) {
    return NextResponse.json({ success: false, error: error.message }, { status: 502 });
  }
  return NextResponse.json({ success: true, data });
}
