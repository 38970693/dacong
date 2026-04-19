/**
 * Search Content Edge Function
 * 搜索内容的API端点 - 使用 PostgreSQL 全文搜索
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
import { withSentry, reportApiError, reportDatabaseError } from "../_shared/monitoring/sentry.ts";

serve(withSentry(async (req) => {
  if (req.method === "OPTIONS") {
    return corsResponse();
  }

  try {
    validateMethod(req, ["GET"]);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const params = getQueryParams(req);

    // 解析查询参数
    const query = params.get("q") || params.get("query") || "";
    const scenario = params.get("scenario") || null;
    const isFree = params.get("is_free") ? params.get("is_free") === "true" : null;
    const availableInChina = params.get("available_in_china")
      ? params.get("available_in_china") === "true"
      : null;
    const sortBy = params.get("sort_by") || "relevance";
    const limit = params.get("limit") ? parseInt(params.get("limit")!) : 20;
    const offset = params.get("offset") ? parseInt(params.get("offset")!) : 0;
    const language = params.get("language") || "zh";

    // 验证查询参数
    if (!query || query.trim().length === 0) {
      return errorResponse("Search query is required", 400);
    }

    // 过滤特殊字符，防止 SQL 注入
    const sanitizedQuery = query.trim().replace(/[^\w\s\u4e00-\u9fa5]/g, " ");

    if (sanitizedQuery.length === 0) {
      return errorResponse("Invalid search query", 400);
    }

    // 调用 PostgreSQL 搜索函数
    const { data, error } = await supabase.rpc("search_content", {
      search_query: sanitizedQuery,
      search_scenario: scenario,
      search_is_free: isFree,
      search_available_in_china: availableInChina,
      sort_by: sortBy,
      result_limit: limit,
      result_offset: offset,
    });

    if (error) {
      reportDatabaseError(error, {
        operation: "search_content",
        table: "contents",
        query: sanitizedQuery,
        extras: { scenario, isFree, availableInChina },
      });
      return errorResponse("Search failed: " + error.message, 500);
    }

    // 格式化响应数据
    const responseData = (data || []).map((row: any) => {
      const titleColumn = language === "zh" ? "title_zh" : "title_en";
      const summaryColumn = language === "zh" ? "summary_zh" : "summary_en";

      return {
        id: row.id,
        content_type: row.content_type,
        title: row[titleColumn] || row.title_zh,
        summary: row[summaryColumn] || row.summary_zh,
        scenario: row.scenario,
        view_count: row.view_count,
        helpful_count: row.helpful_count,
        helpful_rate: row.helpful_count > 0
          ? row.helpful_count / (row.helpful_count + row.unhelpful_count)
          : 0,
        published_at: row.published_at,
        relevance_score: row.relevance_score,
      };
    });

    // 获取总数（用于分页）
    const total = responseData.length;

    return successResponse(responseData, {
      total,
      limit,
      offset,
      query: sanitizedQuery,
      filters: {
        scenario,
        is_free: isFree,
        available_in_china: availableInChina,
      },
      sort_by: sortBy,
    });
  } catch (error) {
    reportApiError(error, {
      endpoint: "/search-content",
      method: req.method,
      extras: {
        query: params.get("q") || params.get("query"),
        scenario: params.get("scenario"),
      },
    });

    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
}, { functionName: "search-content", tags: { service: "search" } }));
