/**
 * Get Hot Searches Edge Function
 * 获取热门搜索词
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
    const limit = params.get("limit") ? parseInt(params.get("limit")!) : 10;

    // 调用 PostgreSQL 函数获取热门搜索
    const { data, error } = await supabase.rpc("get_hot_searches", {
      result_limit: limit,
    });

    if (error) {
      console.error("Get hot searches error:", error);
      return errorResponse("Failed to get hot searches: " + error.message, 500);
    }

    // 格式化响应数据
    const responseData = (data || []).map((row: any) => ({
      query: row.search_query,
      count: row.search_count,
      last_searched_at: row.last_searched_at,
    }));

    return successResponse(responseData, {
      total: responseData.length,
      limit,
    });
  } catch (error) {
    console.error("Error in get-hot-searches:", error);

    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
});
