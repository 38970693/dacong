/**
 * Get AI News Edge Function
 * 统一 AI 资讯出口：基于 hot_news_raw 查询
 * 参数：
 *   - limit          返回条数（默认 20）
 *   - source         来源过滤（如 arxiv / hn / reddit / rss，大小写不敏感）
 *   - sort           排序：recent（按时间，默认）| hot（按热度 score）
 *   - is_ai_related  是否仅 AI 相关（默认 true）
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

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return corsResponse();
  }

  try {
    validateMethod(req, ["GET"]);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const params = getQueryParams(req);
    const limit = params.get("limit") ? parseInt(params.get("limit")!) : 20;
    const source = params.get("source");
    const sort = params.get("sort") === "hot" ? "hot" : "recent";
    // is_ai_related 默认 true，显式传 "false" 时才关闭过滤
    const isAiRelated = params.get("is_ai_related") !== "false";

    let query = supabase.from("hot_news_raw").select("*");

    if (isAiRelated) {
      query = query.eq("is_ai_related", true);
    }

    if (source && source.trim()) {
      // 大小写不敏感精确匹配（hn / HN、arxiv / ARXIV 均可）
      query = query.ilike("source", source.trim());
    }

    if (sort === "hot") {
      query = query
        .order("score", { ascending: false })
        .order("fetched_at", { ascending: false });
    } else {
      query = query.order("fetched_at", { ascending: false });
    }

    const { data, error } = await query.limit(limit);

    if (error) {
      console.error("Get AI news error:", error);
      return errorResponse("Failed to get AI news: " + error.message, 500);
    }

    return successResponse(data || [], {
      total: (data || []).length,
      limit,
      source: source || "all",
      sort,
      is_ai_related: isAiRelated,
    });
  } catch (error) {
    console.error("Error in get-ai-news:", error);

    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
});
