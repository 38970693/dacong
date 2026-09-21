/**
 * Aggregate Evaluations Edge Function
 * 按模型聚合 model_evaluations，生成多 benchmark 对比数据
 *
 * 同一 (模型, benchmark, 分类, 来源) 只保留最新一天的成绩；
 * Arena-ELO 与百分制 benchmark 量纲不同，单独输出、不计入均分。
 *
 * Query 参数（均可选）：
 *   model_id  UUID，只聚合单个模型
 *   days      回溯天数，默认 30
 *   limit     返回模型数 1..200（默认 50）
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  createClient,
  type SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  corsResponse,
  errorResponse,
  getQueryParams,
  successResponse,
  validateMethod,
} from "../_shared/utils/http.ts";
import { withSentry, reportApiError } from "../_shared/monitoring/sentry.ts";

const ELO_BENCHMARK = "Arena-ELO";
const DEFAULT_DAYS = 30;
const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 200;
const PAGE_SIZE = 1000;

interface EvaluationRow {
  model_id: string;
  benchmark: string;
  score: number | null;
  category: string | null;
  source: string;
  eval_date: string;
  models: { name: string; vendor: string } | null;
}

interface ModelAggregate {
  model_id: string;
  name: string | null;
  vendor: string | null;
  eval_date: string;
  benchmark_count: number;
  overall_score: number | null;
  arena_elo: number | null;
  category_scores: Record<string, number>;
  benchmarks: Array<{
    benchmark: string;
    category: string | null;
    source: string;
    score: number | null;
    eval_date: string;
  }>;
}

const round = (value: number) => Number(value.toFixed(4));

const average = (values: number[]) =>
  round(values.reduce((sum, v) => sum + v, 0) / values.length);

/** 分页拉取窗口内的评测记录 */
async function loadEvaluations(
  supabase: SupabaseClient,
  since: string,
  modelId: string | null,
): Promise<EvaluationRow[]> {
  const rows: EvaluationRow[] = [];

  for (let page = 0; ; page++) {
    let query = supabase
      .from("model_evaluations")
      .select(
        "model_id, benchmark, score, category, source, eval_date, models(name, vendor)",
      )
      .gte("eval_date", since);

    if (modelId) {
      query = query.eq("model_id", modelId);
    }

    const { data, error } = await query
      .order("eval_date", { ascending: true })
      .range(page * PAGE_SIZE, (page + 1) * PAGE_SIZE - 1);

    if (error) throw new Error(`读取 model_evaluations 失败: ${error.message}`);
    if (!data || data.length === 0) break;

    rows.push(...(data as unknown as EvaluationRow[]));
    if (data.length < PAGE_SIZE) break;
  }

  return rows;
}

/** 按 model 聚合：去重取最新 + 计算分类均分与总分 */
export function aggregate(rows: EvaluationRow[]): ModelAggregate[] {
  // (model, benchmark, category, source) -> 最新一条（rows 按 eval_date 升序，后写覆盖）
  const latest = new Map<string, EvaluationRow>();
  for (const row of rows) {
    latest.set(
      `${row.model_id}|${row.benchmark}|${row.category ?? ""}|${row.source}`,
      row,
    );
  }

  const grouped = new Map<string, EvaluationRow[]>();
  for (const row of latest.values()) {
    const bucket = grouped.get(row.model_id);
    if (bucket) bucket.push(row);
    else grouped.set(row.model_id, [row]);
  }

  const results: ModelAggregate[] = [];

  for (const [modelId, entries] of grouped) {
    const scored = entries.filter(
      (e) => e.score !== null && e.benchmark !== ELO_BENCHMARK,
    );

    const byCategory = new Map<string, number[]>();
    for (const entry of scored) {
      const key = entry.category ?? "uncategorized";
      const bucket = byCategory.get(key);
      if (bucket) bucket.push(entry.score as number);
      else byCategory.set(key, [entry.score as number]);
    }

    const categoryScores: Record<string, number> = {};
    for (const [category, values] of byCategory) {
      categoryScores[category] = average(values);
    }

    const elo = entries.find((e) => e.benchmark === ELO_BENCHMARK);
    const meta = entries.find((e) => e.models)?.models ?? null;

    results.push({
      model_id: modelId,
      name: meta?.name ?? null,
      vendor: meta?.vendor ?? null,
      eval_date: entries
        .map((e) => e.eval_date)
        .reduce((a, b) => (a > b ? a : b)),
      benchmark_count: entries.length,
      overall_score: scored.length
        ? average(scored.map((e) => e.score as number))
        : null,
      arena_elo: elo?.score ?? null,
      category_scores: categoryScores,
      benchmarks: entries
        .map((e) => ({
          benchmark: e.benchmark,
          category: e.category,
          source: e.source,
          score: e.score,
          eval_date: e.eval_date,
        }))
        .sort((a, b) => a.benchmark.localeCompare(b.benchmark)),
    });
  }

  // 有总分的排前面，其次按总分倒序
  return results.sort(
    (a, b) => (b.overall_score ?? -1) - (a.overall_score ?? -1),
  );
}

serve(withSentry(async (req) => {
  // 处理CORS预检请求
  if (req.method === "OPTIONS") {
    return corsResponse();
  }

  const params = getQueryParams(req);

  try {
    validateMethod(req, ["GET"]);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (!supabaseUrl || !supabaseKey) {
      throw new Error("Missing Supabase configuration");
    }

    // ── 解析并校验参数 ──────────────────────────────
    const modelId = params.get("model_id");

    const rawDays = params.get("days");
    const days = rawDays ? parseInt(rawDays, 10) : DEFAULT_DAYS;
    if (Number.isNaN(days) || days < 1) {
      return errorResponse("Invalid days, expected a positive integer", 400);
    }

    const rawLimit = params.get("limit");
    const parsedLimit = rawLimit ? parseInt(rawLimit, 10) : DEFAULT_LIMIT;
    if (Number.isNaN(parsedLimit) || parsedLimit < 1) {
      return errorResponse("Invalid limit, expected a positive integer", 400);
    }
    const limit = Math.min(parsedLimit, MAX_LIMIT);

    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000)
      .toISOString()
      .split("T")[0];

    const supabase = createClient(supabaseUrl, supabaseKey);
    const rows = await loadEvaluations(supabase, since, modelId);
    const aggregated = aggregate(rows);

    return successResponse(aggregated.slice(0, limit), {
      total: aggregated.length,
      models_returned: Math.min(aggregated.length, limit),
      evaluations_scanned: rows.length,
      since,
    });
  } catch (error) {
    reportApiError(error, {
      endpoint: "/aggregate-evaluations",
      method: req.method,
      extras: {
        model_id: params.get("model_id"),
        days: params.get("days"),
      },
    });

    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
}, { functionName: "aggregate-evaluations", tags: { service: "model-evaluations" } }));
