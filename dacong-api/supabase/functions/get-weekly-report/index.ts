/**
 * Get Weekly Report Edge Function
 * 获取周报的API端点
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { Container } from "../_shared/core/Container.ts";
import { ContentType } from "../_shared/domain/Content.ts";
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

    const container = Container.getInstance(supabase);

    const params = getQueryParams(req);
    const language = params.get("language") || "zh";
    const limit = params.get("limit") ? parseInt(params.get("limit")!) : 10;
    const weeklyId = params.get("id"); // 获取特定周报

    let query = supabase
      .from("published_content")
      .select("*")
      .eq("content_type", ContentType.WEEKLY);

    // 如果指定了 ID，只获取该周报
    if (weeklyId) {
      query = query.eq("id", weeklyId).limit(1);
    } else {
      // 否则获取最新的周报列表
      query = query.order("published_at", { ascending: false }).limit(limit);
    }

    const { data, error } = await query;

    if (error) {
      throw new Error(`Failed to fetch weekly reports: ${error.message}`);
    }

    if (!data || data.length === 0) {
      return successResponse(weeklyId ? null : [], {
        total: 0,
        language,
      });
    }

    const responseData = data.map((row) => {
      const content = language === "zh" ? row.content_zh : (row.content_en || row.content_zh);

      return {
        id: row.id,
        content_type: row.content_type,
        title: language === "zh" ? row.title_zh : (row.title_en || row.title_zh),
        summary: language === "zh" ? row.summary_zh : (row.summary_en || row.summary_zh),
        week_start: content?.week_start || "",
        week_end: content?.week_end || "",
        sections: content?.sections || [],
        view_count: row.view_count,
        helpful_count: row.helpful_count,
        helpful_rate:
          row.helpful_count + row.unhelpful_count > 0
            ? row.helpful_count / (row.helpful_count + row.unhelpful_count)
            : null,
        published_at: row.published_at,
      };
    });

    // 如果是获取单个周报，返回对象而不是数组
    if (weeklyId) {
      return successResponse(responseData[0], {
        language,
      });
    }

    return successResponse(responseData, {
      total: responseData.length,
      language,
    });
  } catch (error) {
    console.error("Error in get-weekly-report:", error);

    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
});
