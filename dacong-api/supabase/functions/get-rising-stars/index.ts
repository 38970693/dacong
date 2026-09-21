/**
 * Get Rising Stars Edge Function
 * GitHub 飙升榜查询接口（读取 compute-rising-stars 生成的最新快照）
 *
 * Query 参数：
 *   period   1d | 7d | 30d  （默认 7d）
 *   limit    1..100         （默认 20）
 *   language 可选，按编程语言过滤
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

const SORT_COLUMN: Record<string, string> = {
  "1d": "stars_1d",
  "7d": "stars_7d",
  "30d": "stars_30d",
};

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 100;

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
    const period = params.get("period") ?? "7d";
    const sortColumn = SORT_COLUMN[period];
    if (!sortColumn) {
      return errorResponse("Invalid period, expected one of: 1d, 7d, 30d", 400);
    }

    const rawLimit = params.get("limit");
    const parsedLimit = rawLimit ? parseInt(rawLimit, 10) : DEFAULT_LIMIT;
    if (Number.isNaN(parsedLimit) || parsedLimit < 1) {
      return errorResponse("Invalid limit, expected a positive integer", 400);
    }
    const limit = Math.min(parsedLimit, MAX_LIMIT);

    const language = params.get("language");

    const supabase = createClient(supabaseUrl, supabaseKey);

    // ── 定位最新快照日 ──────────────────────────────
    const { data: latest, error: latestError } = await supabase
      .from("rising_stars_rankings")
      .select("snapshot_date")
      .order("snapshot_date", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (latestError) {
      throw new Error(latestError.message);
    }
    if (!latest) {
      // 尚未跑过 compute-rising-stars
      return successResponse([], { total: 0, period, snapshot_date: null });
    }

    const snapshotDate = latest.snapshot_date as string;

    // ── 查询 Top N ────────────────────────────────
    let query = supabase
      .from("rising_stars_rankings")
      .select(
        "repo_name, repo_url, owner, language, description, " +
          "total_stars, stars_1d, stars_7d, stars_30d, velocity, rank_score, snapshot_date",
      )
      .eq("snapshot_date", snapshotDate);

    if (language) {
      query = query.eq("language", language);
    }

    const { data, error } = await query
      .order(sortColumn, { ascending: false })
      .order("rank_score", { ascending: false })
      .limit(limit);

    if (error) {
      throw new Error(error.message);
    }

    return successResponse(data ?? [], {
      total: data?.length ?? 0,
      period,
      language,
      snapshot_date: snapshotDate,
    });
  } catch (error) {
    reportApiError(error, {
      endpoint: "/get-rising-stars",
      method: req.method,
      extras: {
        period: params.get("period"),
        language: params.get("language"),
      },
    });

    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
}, { functionName: "get-rising-stars", tags: { service: "rising-stars" } }));
