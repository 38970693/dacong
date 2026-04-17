// Edge Function: compute-ranks
// 每天定时计算模型排名
// 触发方式：cron job 或 postgrest webhook
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface ModelScore {
  model_id: string
  github_stars: number
  hf_downloads: number
  hn_count: number
  overall: number
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: { 'Access-Control-Allow-Origin': '*' } })
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

  // 获取过去24h的原始指标
  const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()

  // 1. GitHub stars 汇总
  const { data: ghData } = await supabase
    .from('repository_metrics')
    .select('repo_name, stars, is_ai_related')
    .eq('is_ai_related', true)
    .gte('fetched_at', since)

  const ghScore: Record<string, number> = {}
  for (const row of ghData ?? []) {
    ghScore[row.repo_name] = Math.max(ghScore[row.repo_name] ?? 0, row.stars)
  }

  // 2. HuggingFace downloads 汇总
  const { data: hfData } = await supabase
    .from('model_raw_metrics')
    .select('model_id, value')
    .eq('metric_type', 'hf_text_generation')
    .gte('fetched_at', since)

  const hfScore: Record<string, number> = {}
  for (const row of hfData ?? []) {
    hfScore[row.model_id] = (hfScore[row.model_id] ?? 0) + (row.value ?? 0)
  }

  // 3. HackerNews 新闻数
  const { data: hnData } = await supabase
    .from('hot_news_raw')
    .select('title')
    .eq('is_ai_related', true)
    .gte('fetched_at', since)

  // 合并到 models 表并计算排名
  const { data: models } = await supabase.from('models').select('id, category')

  const scores: ModelScore[] = (models ?? []).map(m => {
    const github_stars = ghScore[m.id] ?? 0
    const hf_downloads = hfScore[m.id] ?? 0
    const hn_count = (hnData ?? []).filter(n => n.title.includes(m.id)).length
    // 综合得分：GitHub 40% + HF 50% + HN 10%
    const overall = github_stars * 0.4 + hf_downloads * 0.5 + hn_count * 100
    return { model_id: m.id, github_stars, hf_downloads, hn_count, overall }
  })

  // 排序并写入排名表
  const today = new Date().toISOString().split('T')[0]

  for (let i = 0; i < scores.length; i++) {
    const s = scores[i]
    const rank_overall = i + 1
    await supabase.from('model_ranks').upsert({
      model_id: s.model_id,
      rank_date: today,
      rank_overall,
      score: s.overall,
      github_stars: s.github_stars,
      hf_downloads: s.hf_downloads,
      hn_news_count: s.hn_count,
    }, { onConflict: 'model_id,rank_date' })
  }

  return new Response(JSON.stringify({ ok: true, ranked: scores.length }), {
    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
  })
})
