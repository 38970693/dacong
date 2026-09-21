/**
 * Get Model Comparison Edge Function
 * 大模型能力横评接口（读取 models 能力字段 + 评测/价格补充）
 *
 * Query 参数：
 *   ids       逗号分隔的 model id（UUID）列表，优先级高于 category
 *   category  按 models.category 过滤（ids 未提供时使用）
 *   limit     1..20（默认 10），对比表列数上限
 *
 * 返回 data 为模型数组，每项含能力字段 + evaluations（benchmark → 最新分数）；
 * meta.benchmarks 给出所有模型评测项的并集，便于前端拼固定行的横评表。
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  corsResponse,
  errorResponse,
  getQueryParams,
  successResponse,
  validateMethod,
} from "../_shared/utils/http.ts";
import { withSentry, reportApiError } from "../_shared/monitoring/sentry.ts";

const DEFAULT_LIMIT = 10;
const MAX_LIMIT = 20;

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** models 表需要的能力字段（含 M3 新增列） */
const MODEL_FIELDS = [
  "id",
  "name",
  "vendor",
  "category",
  "description",
  "website_url",
  "is_open_source",
  "context_window",
  "max_output_tokens",
  "latency_ms",
  "throughput_tps",
  "multimodal_inputs",
  "tool_use",
  "fine_tunable",
].join(", ");

interface ModelRow {
  id: string;
  name: string;
  vendor: string;
  category: string;
  description: string | null;
  website_url: string | null;
  is_open_source: boolean | null;
  context_window: number | null;
  max_output_tokens: number | null;
  latency_ms: number | null;
  throughput_tps: number | null;
  multimodal_inputs: string[] | null;
  tool_use: boolean | null;
  fine_tunable: boolean | null;
}

interface EvaluationRow {
  model_id: string;
  benchmark: string;
  score: number | null;
  category: string | null;
  source: string;
  eval_date: string;
}

interface PricingRow {
  model_name: string;
  price_1m_input_tokens: number | null;
  price_1m_output_tokens: number | null;
  context_window_tokens: number | null;
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
    const rawIds = params.get("ids");
    const category = params.get("category");

    const ids = rawIds
      ? rawIds.split(",").map((s) => s.trim()).filter(Boolean)
      : [];

    if (!rawIds && !category) {
      return errorResponse("Either ids or category is required", 400);
    }
    if (rawIds && ids.length === 0) {
      return errorResponse("ids is empty", 400);
    }
    const invalidId = ids.find((id) => !UUID_RE.test(id));
    if (invalidId) {
      return errorResponse(`Invalid model id: ${invalidId}`, 400);
    }

    const rawLimit = params.get("limit");
    const parsedLimit = rawLimit ? parseInt(rawLimit, 10) : DEFAULT_LIMIT;
    if (Number.isNaN(parsedLimit) || parsedLimit < 1) {
      return errorResponse("Invalid limit, expected a positive integer", 400);
    }
    const limit = Math.min(parsedLimit, MAX_LIMIT);

    const supabase = createClient(supabaseUrl, supabaseKey);

    // ── 1. 取模型能力字段 ───────────────────────────
    let modelQuery = supabase.from("models").select(MODEL_FIELDS);

    if (ids.length > 0) {
      modelQuery = modelQuery.in("id", ids);
    } else {
      modelQuery = modelQuery.eq("category", category!);
    }

    const { data: modelData, error: modelError } = await modelQuery
      .order("name", { ascending: true })
      .limit(limit);

    if (modelError) {
      throw new Error(modelError.message);
    }

    // select 字段是运行时拼接的字符串，supabase-js 无法推断行类型
    const models = (modelData ?? []) as unknown as ModelRow[];
    if (models.length === 0) {
      return successResponse([], { total: 0, benchmarks: [] });
    }

    const modelIds = models.map((m) => m.id);
    const modelNames = models.map((m) => m.name);

    // ── 2. 评测成绩 + 价格补充（失败不阻塞主数据）─────
    const [evalResult, pricingResult] = await Promise.all([
      supabase
        .from("model_evaluations")
        .select("model_id, benchmark, score, category, source, eval_date")
        .in("model_id", modelIds)
        .order("eval_date", { ascending: false }),
      supabase
        .from("artificial_analysis_rankings")
        .select(
          "model_name, price_1m_input_tokens, price_1m_output_tokens, " +
            "context_window_tokens",
        )
        .in("model_name", modelNames),
    ]);

    const evaluations = (evalResult.data ?? []) as EvaluationRow[];
    const pricings = (pricingResult.data ?? []) as unknown as PricingRow[];

    // model_id → { benchmark → 最新一条 }（已按 eval_date 倒序，首次出现即最新）
    const evalByModel = new Map<string, Record<string, EvaluationRow>>();
    for (const row of evaluations) {
      const byBenchmark = evalByModel.get(row.model_id) ?? {};
      if (!(row.benchmark in byBenchmark)) {
        byBenchmark[row.benchmark] = row;
        evalByModel.set(row.model_id, byBenchmark);
      }
    }

    const pricingByName = new Map<string, PricingRow>(
      pricings.map((p) => [p.model_name, p]),
    );

    // ── 3. 组装对比行 ───────────────────────────────
    const data = models.map((model) => {
      const byBenchmark = evalByModel.get(model.id) ?? {};
      const pricing = pricingByName.get(model.name);

      return {
        ...model,
        // AA 的 context_window_tokens 作为 models.context_window 的兜底
        context_window: model.context_window ??
          pricing?.context_window_tokens ?? null,
        multimodal_inputs: model.multimodal_inputs ?? [],
        price_1m_input_tokens: pricing?.price_1m_input_tokens ?? null,
        price_1m_output_tokens: pricing?.price_1m_output_tokens ?? null,
        evaluations: Object.values(byBenchmark).map((e) => ({
          benchmark: e.benchmark,
          score: e.score,
          category: e.category,
          source: e.source,
          eval_date: e.eval_date,
        })),
      };
    });

    // 所有模型评测项的并集，作为横评表的固定行
    const benchmarks = [
      ...new Set(evaluations.map((e) => e.benchmark)),
    ].sort();

    return successResponse(data, {
      total: data.length,
      benchmarks,
      category: ids.length > 0 ? null : category,
    });
  } catch (error) {
    reportApiError(error, {
      endpoint: "/get-model-comparison",
      method: req.method,
      extras: {
        ids: params.get("ids"),
        category: params.get("category"),
      },
    });

    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
}, { functionName: "get-model-comparison", tags: { service: "model-comparison" } }));
