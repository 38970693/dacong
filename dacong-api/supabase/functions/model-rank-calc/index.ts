/**
 * DaCong Edge Function: model-rank-calc
 * 根据爬虫写入的 model_raw_metrics 数据计算综合排名
 * 触发方式：
 *   1. cron job 定时触发（每小时）
 *   2. HTTP POST（手动触发）
 * 
 * 评分算法：
 *   GitHub stars  × 1.0
 *   HuggingFace downloads × 0.1
 *   归一化后加权求和
 */
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface RankScore {
  model_id: string;
  github_stars: number;
  hf_downloads: number;
  total_score: number;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // ── 拉取最新原始指标（最近 24h）─────────────────────
    const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

    const { data: metrics, error: metricsErr } = await supabase
      .from("model_raw_metrics")
      .select("model_id, source, metric_type, metric_value, fetched_at")
      .gte("fetched_at", cutoff)
      .in("source", ["github", "huggingface"]);

    if (metricsErr) throw metricsErr;
    if (!metrics?.length) {
      return new Response(JSON.stringify({ ok: true, message: "No metrics found, skipping." }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── 按 model_id 聚合分数 ────────────────────────────
    const scoreMap = new Map<string, RankScore>();

    for (const m of metrics) {
      const val = m.metric_value as Record<string, unknown>;
      if (!scoreMap.has(m.model_id)) {
        scoreMap.set(m.model_id, { model_id: m.model_id, github_stars: 0, hf_downloads: 0, total_score: 0 });
      }
      const s = scoreMap.get(m.model_id)!;

      if (m.source === "github") {
        // 优先用 stars_today，也可用 total_stars_raw
        const stars = Number(val["stars_today"] ?? val["total_stars_raw"] ?? 0);
        s.github_stars = Math.max(s.github_stars, stars);
      } else if (m.source === "huggingface") {
        const downloads = Number(val["downloads"] ?? 0);
        s.hf_downloads = Math.max(s.hf_downloads, downloads);
      }
    }

    // ── 归一化 & 评分 ──────────────────────────────────
    const entries = Array.from(scoreMap.values());
    const maxGithub = Math.max(...entries.map((e) => e.github_stars), 1);
    const maxHf = Math.max(...entries.map((e) => e.hf_downloads), 1);

    for (const e of entries) {
      e.total_score =
        (e.github_stars / maxGithub) * 70 +
        (e.hf_downloads / maxHf) * 30;
    }

    // 按综合分排序
    entries.sort((a, b) => b.total_score - a.total_score);

    // ── 写入 model_ranks ──────────────────────────────
    const now = new Date().toISOString();
    const upserts = entries.map((e, idx) => ({
      model_id: e.model_id,
      rank_overall: idx + 1,
      score: Math.round(e.total_score * 100) / 100,
      rank_updated_at: now,
    }));

    const { error: upsertErr } = await supabase
      .from("model_ranks")
      .upsert(upserts, { onConflict: "model_id" });

    if (upsertErr) throw upsertErr;

    return new Response(
      JSON.stringify({ ok: true, ranked: upserts.length }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
