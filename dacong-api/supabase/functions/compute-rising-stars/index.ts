// Edge Function: compute-rising-stars
// 每日计算 GitHub 飙升榜快照，写入 rising_stars_rankings
// 触发方式：cron job（建议每日 02:00 UTC）或手动调用
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const WINDOW_DAYS = 30
const PAGE_SIZE = 1000
const UPSERT_CHUNK = 500
const DAY_MS = 24 * 60 * 60 * 1000

interface MetricRow {
  repo_name: string
  repo_url: string
  language: string | null
  description: string | null
  author: string | null
  stars: number | null
  fetched_at: string
}

interface Point {
  t: number // fetched_at 毫秒时间戳
  stars: number
}

/**
 * 对 (天数, 累计 star 数) 序列做最小二乘线性拟合，返回斜率（stars/day）
 * 与 dacong-spider/spiders/github_trending.py 的 compute_velocity 保持一致
 */
export function computeVelocity(points: Array<[number, number]>): number {
  const n = points.length
  if (n < 2) return 0

  let sumX = 0, sumY = 0, sumXY = 0, sumXX = 0
  for (const [x, y] of points) {
    sumX += x
    sumY += y
    sumXY += x * y
    sumXX += x * x
  }

  const denominator = n * sumXX - sumX * sumX
  if (denominator === 0) return 0

  return (n * sumXY - sumX * sumY) / denominator
}

/** 综合排序分：0.5*stars_7d + 0.3*velocity + 0.2*stars_1d */
export function computeRankScore(stars1d: number, stars7d: number, velocity: number): number {
  return 0.5 * stars7d + 0.3 * velocity + 0.2 * stars1d
}

/**
 * 计算最近 days 天的 star 增量
 * 基线取「不晚于 cutoff 的最后一个点」，没有则退化为窗口内最早的点
 * （时间序列可能因爬取失败断点，这里容忍缺失而不插值）
 */
function starsDelta(series: Point[], days: number, now: number): number {
  const latest = series[series.length - 1]
  const cutoff = now - days * DAY_MS

  let baseline = series[0]
  for (const p of series) {
    if (p.t <= cutoff) baseline = p
    else break
  }

  return Math.max(0, latest.stars - baseline.stars)
}

/** 分页拉取窗口内全部 repository_metrics */
async function loadMetrics(
  supabase: ReturnType<typeof createClient>,
  since: string,
): Promise<MetricRow[]> {
  const rows: MetricRow[] = []

  for (let page = 0; ; page++) {
    const { data, error } = await supabase
      .from('repository_metrics')
      .select('repo_name, repo_url, language, description, author, stars, fetched_at')
      .gte('fetched_at', since)
      .order('fetched_at', { ascending: true })
      .range(page * PAGE_SIZE, (page + 1) * PAGE_SIZE - 1)

    if (error) throw new Error(`读取 repository_metrics 失败: ${error.message}`)
    if (!data || data.length === 0) break

    rows.push(...(data as MetricRow[]))
    if (data.length < PAGE_SIZE) break
  }

  return rows
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: { 'Access-Control-Allow-Origin': '*' } })
  }

  const headers = { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    const now = Date.now()
    const since = new Date(now - WINDOW_DAYS * DAY_MS).toISOString()
    const snapshotDate = new Date(now).toISOString().split('T')[0]

    const rows = await loadMetrics(supabase, since)

    // 按 repo 聚合时间序列（同一天多条时保留最后一条）
    const grouped = new Map<string, { meta: MetricRow; series: Point[] }>()
    for (const row of rows) {
      if (row.stars === null) continue

      const entry = grouped.get(row.repo_name)
      const point: Point = { t: new Date(row.fetched_at).getTime(), stars: row.stars }

      if (entry) {
        entry.meta = row // rows 按时间升序，末条即最新元数据
        entry.series.push(point)
      } else {
        grouped.set(row.repo_name, { meta: row, series: [point] })
      }
    }

    const records = []
    for (const [repoName, { meta, series }] of grouped) {
      // 单点无法体现增速，跳过
      if (series.length < 2) continue

      const stars1d = starsDelta(series, 1, now)
      const stars7d = starsDelta(series, 7, now)
      const stars30d = starsDelta(series, WINDOW_DAYS, now)

      // x 轴用「距窗口起点的天数」，避免大数值放大浮点误差
      const originT = series[0].t
      const velocity = computeVelocity(
        series.map((p) => [(p.t - originT) / DAY_MS, p.stars] as [number, number]),
      )

      records.push({
        repo_name: repoName,
        repo_url: meta.repo_url,
        owner: meta.author ?? repoName.split('/')[0],
        language: meta.language,
        description: meta.description,
        total_stars: series[series.length - 1].stars,
        stars_1d: stars1d,
        stars_7d: stars7d,
        stars_30d: stars30d,
        velocity: Number(velocity.toFixed(4)),
        rank_score: Number(computeRankScore(stars1d, stars7d, velocity).toFixed(4)),
        snapshot_date: snapshotDate,
      })
    }

    for (let i = 0; i < records.length; i += UPSERT_CHUNK) {
      const { error } = await supabase
        .from('rising_stars_rankings')
        .upsert(records.slice(i, i + UPSERT_CHUNK), { onConflict: 'repo_name,snapshot_date' })

      if (error) throw new Error(`写入 rising_stars_rankings 失败: ${error.message}`)
    }

    return new Response(
      JSON.stringify({
        ok: true,
        snapshot_date: snapshotDate,
        repos_scanned: grouped.size,
        repos_ranked: records.length,
      }),
      { headers },
    )
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Internal server error'
    return new Response(JSON.stringify({ ok: false, error: message }), { status: 500, headers })
  }
})
