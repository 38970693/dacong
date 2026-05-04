import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const type = searchParams.get('type') || '全部';
    const sort = searchParams.get('sort') || '最新';
    const limit = parseInt(searchParams.get('limit') || '20');

    let query = supabase
      .from('reviews')
      .select('*')
      .eq('status', 'published')
      .order(sort === '评分最高' ? 'rating' : 'created_at', { ascending: false })
      .limit(limit);

    if (type !== '全部') {
      query = query.eq('review_type', type);
    }

    const { data, error } = await query;

    if (error) throw error;

    return NextResponse.json({ success: true, data });
  } catch (error) {
    console.error('Reviews API error:', error);
    return NextResponse.json({ success: false, error: 'Failed to fetch reviews' }, { status: 500 });
  }
}