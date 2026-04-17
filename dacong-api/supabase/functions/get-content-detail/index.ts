/**
 * Get Content Detail Edge Function with Sentry Integration
 * 获取内容详情的API端点
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { Container } from "../_shared/core/Container.ts";
import { GetContentDetailRequestSchema } from "../_shared/dto/GetContentDetailRequest.ts";
import {
  corsResponse,
  errorResponse,
  getQueryParams,
  successResponse,
  validateMethod,
} from "../_shared/utils/http.ts";
import { initSentry, withSentry } from "../_shared/utils/sentry.ts";

// 初始化 Sentry
initSentry({
  functionName: "get-content-detail",
});

serve(
  withSentry(
    async (req) => {
      if (req.method === "OPTIONS") {
        return corsResponse();
      }

      validateMethod(req, ["GET"]);

      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;
      const supabase = createClient(supabaseUrl, supabaseKey);

      const container = Container.getInstance(supabase);
      const contentService = container.getContentService();

      const params = getQueryParams(req);
      const requestData = {
        id: params.get("id"),
        language: params.get("language") || "zh",
        incrementView: params.get("incrementView") !== "false",
      };

      const validatedData = GetContentDetailRequestSchema.parse(requestData);

      const content = await contentService.getContentDetail(
        validatedData.id,
        validatedData.incrementView,
      );

      if (!content) {
        return errorResponse("Content not found", 404);
      }

      const json = content.toJSON();
      const responseData =
        validatedData.language === "zh"
          ? {
            id: json.id,
            content_type: json.content_type,
            title: json.title_zh,
            summary: json.summary_zh,
            content: json.content_zh,
            scenario: json.scenario,
            view_count: json.view_count,
            helpful_count: json.helpful_count,
            unhelpful_count: json.unhelpful_count,
            share_count: json.share_count,
            helpful_rate: json.helpful_rate,
            published_at: json.published_at,
            updated_at: json.updated_at,
          }
          : {
            id: json.id,
            content_type: json.content_type,
            title: json.title_en || json.title_zh,
            summary: json.summary_en || json.summary_zh,
            content: json.content_en || json.content_zh,
            scenario: json.scenario,
            view_count: json.view_count,
            helpful_count: json.helpful_count,
            unhelpful_count: json.unhelpful_count,
            share_count: json.share_count,
            helpful_rate: json.helpful_rate,
            published_at: json.published_at,
            updated_at: json.updated_at,
          };

      return successResponse(responseData);
    },
    {
      functionName: "get-content-detail",
      captureErrors: true,
    },
  ),
);
