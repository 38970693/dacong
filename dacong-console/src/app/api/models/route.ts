import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const category = searchParams.get('category') || '综合';
    const timeRange = searchParams.get('timeRange') || 'all';

    let query = supabase
      .from('models')
      .select('*')
      .eq('is_active', true)
      .order('score', { ascending: false });

    if (category !== '全部') {
      query = query.eq('category', category);
    }

    const { data, error } = await query;

    if (error) throw error;

    return NextResponse.json({ success: true, data });
  } catch (err) {
    console.error('Models API error:', err);
    return NextResponse.json({ success: false, error: 'Failed to fetch models' }, { status: 500 });
  }
}