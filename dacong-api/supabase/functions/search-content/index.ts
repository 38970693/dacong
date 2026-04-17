/**
 * Search Content Edge Function
 * 搜索内容的API端点
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { Container } from "../_shared/core/Container.ts";
import { SearchContentRequestSchema } from "../_shared/dto/SearchContentRequest.ts";
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
    const contentService = container.getContentService();

    const params = getQueryParams(req);
    const requestData = {
      query: params.get("query"),
      language: params.get("language") || "zh",
      limit: params.get("limit") ? parseInt(params.get("limit")!) : 20,
      offset: params.get("offset") ? parseInt(params.get("offset")!) : 0,
    };

    const validatedData = SearchContentRequestSchema.parse(requestData);

    const { items, total } = await contentService.searchContent(
      validatedData.query,
      validatedData.language as "zh" | "en",
      validatedData.limit,
      validatedData.offset
    );

    const responseData = items.map((content) => {
      const json = content.toJSON();
      return validatedData.language === "zh"
        ? {
            id: json.id,
            content_type: json.content_type,
            title: json.title_zh,
            summary: json.summary_zh,
            scenario: json.scenario,
            view_count: json.view_count,
            helpful_count: json.helpful_count,
            helpful_rate: json.helpful_rate,
            published_at: json.published_at,
          }
        : {
            id: json.id,
            content_type: json.content_type,
            title: json.title_en || json.title_zh,
            summary: json.summary_en || json.summary_zh,
            scenario: json.scenario,
            view_count: json.view_count,
            helpful_count: json.helpful_count,
            helpful_rate: json.helpful_rate,
            published_at: json.published_at,
          };
    });

    return successResponse(responseData, {
      total,
      limit: validatedData.limit,
      offset: validatedData.offset,
      query: validatedData.query,
    });
  } catch (error) {
    console.error("Error in search-content:", error);

    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
});
