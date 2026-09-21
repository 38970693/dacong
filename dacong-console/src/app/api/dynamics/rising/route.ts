// Static export mode: exclude from static generation
export const dynamic = 'force-static';

// AI 动态 - 飙升榜数据源
// 读取 compute-rising-stars 生成的最新快照（rising_stars_rankings），按涨速排序
import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
);

export async function GET(request: NextRequest) {
  try {
    const sp = request.nextUrl.searchParams;

    const limit = Math.min(Math.max(Number(sp.get('limit')) || 20, 1), 100);
    const language = sp.get('language');
    // velocity = 按涨速（正在火）；1d/7d/30d = 按对应窗口的绝对增量
    const sortBy = sp.get('sort') === 'stars' ? 'stars' : 'velocity';

    // 取最新快照日期，避免跨日期数据混排
    const { data: latest, error: latestError } = await supabase
      .from('rising_stars_rankings')
      .select('snapshot_date')
      .order('snapshot_date', { ascending: false })
      .limit(1)
      .maybeSingle();

    // 连接失败必须抛错，否则会被静默成「暂无数据」，掩盖真实故障
    if (latestError) throw latestError;

    if (!latest) {
      return NextResponse.json({ success: true, data: [], meta: { snapshot_date: null } });
    }

    let query = supabase
      .from('rising_stars_rankings')
      .select('*')
      .eq('snapshot_date', latest.snapshot_date)
      .order(sortBy === 'stars' ? 'stars_7d' : 'velocity', { ascending: false })
      .limit(limit);

    if (language) {
      query = query.eq('language', language);
    }

    const { data, error } = await query;
    if (error) throw error;

    return NextResponse.json({
      success: true,
      data: data ?? [],
      meta: { snapshot_date: latest.snapshot_date, sort: sortBy, total: data?.length ?? 0 },
    });
  } catch (err) {
    console.error('[dynamics/rising]', err);
    return NextResponse.json(
      { success: false, data: [], error: 'Failed to fetch rising stars' },
      { status: 200 },
    );
  }
}
