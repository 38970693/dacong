/**
 * Get Model Evaluations Edge Function
 * 大模型评测成绩查询接口（读取 model_evaluations）
 *
 * Query 参数（均可选，组合过滤）：
 *   model_id   UUID，按模型过滤
 *   benchmark  如 MMLU-Pro / GPQA / Arena-ELO
 *   category   general | coding | math | vision | chinese | agentic
 *   limit      1..200（默认 100）
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

const DEFAULT_LIMIT = 100;
const MAX_LIMIT = 200;

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
    const benchmark = params.get("benchmark");
    const category = params.get("category");

    const rawLimit = params.get("limit");
    const parsedLimit = rawLimit ? parseInt(rawLimit, 10) : DEFAULT_LIMIT;
    if (Number.isNaN(parsedLimit) || parsedLimit < 1) {
      return errorResponse("Invalid limit, expected a positive integer", 400);
    }
    const limit = Math.min(parsedLimit, MAX_LIMIT);

    const supabase = createClient(supabaseUrl, supabaseKey);

    let query = supabase
      .from("model_evaluations")
      .select(
        "model_id, benchmark, score, category, source, eval_date, raw_data, " +
          "models(name, vendor)",
      );

    if (modelId) {
      query = query.eq("model_id", modelId);
    }
    if (benchmark) {
      query = query.eq("benchmark", benchmark);
    }
    if (category) {
      query = query.eq("category", category);
    }

    const { data, error } = await query
      .order("eval_date", { ascending: false })
      .order("score", { ascending: false })
      .limit(limit);

    if (error) {
      throw new Error(error.message);
    }

    return successResponse(data ?? [], {
      total: data?.length ?? 0,
      model_id: modelId,
      benchmark,
      category,
    });
  } catch (error) {
    reportApiError(error, {
      endpoint: "/get-model-evaluations",
      method: req.method,
      extras: {
        model_id: params.get("model_id"),
        benchmark: params.get("benchmark"),
        category: params.get("category"),
      },
    });

    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
}, { functionName: "get-model-evaluations", tags: { service: "model-evaluations" } }));
