export const dynamic = 'force-dynamic';

// AI 动态 - 模型脉搏数据源
// 读取 model_evaluations（按 eval_date 留历史），关联 models 拿模型名
import { createClient } from '@supabase/supabase-js';
import { NextRequest, NextResponse } from 'next/server';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
);

export async function GET(request: NextRequest) {
  try {
    const sp = request.nextUrl.searchParams;
    const model = sp.get('model');
    const benchmark = sp.get('benchmark');
    const days = Math.min(Math.max(Number(sp.get('days')) || 180, 1), 730);

    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000)
      .toISOString()
      .split('T')[0];

    let query = supabase
      .from('model_evaluations')
      .select('benchmark, score, category, source, eval_date, models(name, vendor)')
      .gte('eval_date', since)
      .order('eval_date', { ascending: true })
      .limit(2000);

    if (benchmark) query = query.eq('benchmark', benchmark);
    if (model) query = query.eq('models.name', model);

    const { data, error } = await query;
    if (error) throw error;

    // Supabase 类型推断把多对一关联推成数组，运行时实际是单个对象，这里两种都兼容
    type Joined = { name: string; vendor: string | null };
    const rows = (data ?? []) as unknown as Array<{
      benchmark: string;
      score: number | null;
      category: string | null;
      source: string;
      eval_date: string;
      models: Joined | Joined[] | null;
    }>;

    // 按「模型名 + benchmark」聚成时间序列，供前端画曲线
    const seriesMap = new Map<string, {
      model: string;
      vendor: string | null;
      benchmark: string;
      points: Array<{ date: string; score: number }>;
    }>();

    for (const r of rows) {
      if (r.score === null) continue;
      const joined = Array.isArray(r.models) ? r.models[0] : r.models;
      const name = joined?.name ?? 'unknown';
      const key = `${name}::${r.benchmark}`;
      const entry = seriesMap.get(key) ?? {
        model: name,
        vendor: joined?.vendor ?? null,
        benchmark: r.benchmark,
        points: [],
      };
      entry.points.push({ date: r.eval_date, score: Number(r.score) });
      seriesMap.set(key, entry);
    }

    const series = [...seriesMap.values()];
    const models = [...new Set(series.map((s) => s.model))].sort();
    const benchmarks = [...new Set(series.map((s) => s.benchmark))].sort();

    return NextResponse.json({
      success: true,
      data: { series, models, benchmarks },
      meta: { total: series.length, days },
    }, { headers: { 'Cache-Control': 'public, s-maxage=1800, stale-while-revalidate=120' } });
  } catch (err) {
    console.error('[dynamics/pulse]', err);
    return NextResponse.json(
      { success: false, data: { series: [], models: [], benchmarks: [] }, error: 'Failed to fetch evaluations' },
      { status: 503 },
    );
  }
}
