/**
 * Get Recommendations Edge Function - v1
 * 获取场景推荐的API端点 - 版本1
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { Container } from "../../_shared/core/Container.ts";
import { GetRecommendationsRequestSchema } from "../../_shared/dto/GetRecommendationsRequest.ts";
import { Scenario } from "../../_shared/domain/Content.ts";
import {
  corsResponse,
  errorResponse,
  getQueryParams,
  successResponse,
  validateMethod,
} from "../../_shared/utils/http.ts";
import {
  versionMiddleware,
  addDeprecationHeaders,
} from "../../_shared/middleware/versioning.ts";

serve(async (req) => {
  // 处理CORS预检请求
  if (req.method === "OPTIONS") {
    return corsResponse();
  }

  try {
    // 获取API版本
    const apiVersion = versionMiddleware(req);

    // 验证请求方法
    validateMethod(req, ["GET"]);

    // 初始化Supabase客户端
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (!supabaseUrl || !supabaseKey) {
      throw new Error("Missing Supabase configuration");
    }

    const supabase = createClient(supabaseUrl, supabaseKey);

    // 获取依赖注入容器
    const container = Container.getInstance(supabase);
    const recommendationService = container.getRecommendationService();

    // 解析查询参数
    const params = getQueryParams(req);
    const requestData = {
      scenario: params.get("scenario"),
      language: params.get("language") || "zh",
      limit: params.get("limit") ? parseInt(params.get("limit")!) : 20,
    };

    // 验证请求参数
    const validatedData = GetRecommendationsRequestSchema.parse(requestData);

    // 获取推荐内容（使用增强的推荐服务）
    const recommendations = await recommendationService.getRecommendationsWithContent(
      validatedData.scenario as Scenario,
      validatedData.limit
    );

    // 转换为JSON格式
    const responseData = recommendations.map((content) => {
      const json = content.toJSON();
      // 根据语言过滤字段
      if (validatedData.language === "zh") {
        return {
          id: json.id,
          content_type: json.content_type,
          title: json.title_zh,
          summary: json.summary_zh,
          content: json.content_zh,
          scenario: json.scenario,
          view_count: json.view_count,
          helpful_count: json.helpful_count,
          unhelpful_count: json.unhelpful_count,
          helpful_rate: json.helpful_rate,
          published_at: json.published_at,
        };
      } else {
        return {
          id: json.id,
          content_type: json.content_type,
          title: json.title_en || json.title_zh,
          summary: json.summary_en || json.summary_zh,
          content: json.content_en || json.content_zh,
          scenario: json.scenario,
          view_count: json.view_count,
          helpful_count: json.helpful_count,
          unhelpful_count: json.unhelpful_count,
          helpful_rate: json.helpful_rate,
          published_at: json.published_at,
        };
      }
    });

    // 创建响应头并添加版本信息
    const headers = new Headers({
      "Content-Type": "application/json",
    });
    addDeprecationHeaders(headers, apiVersion);

    return new Response(
      JSON.stringify({
        success: true,
        data: responseData,
        meta: {
          total: recommendations.length,
          scenario: validatedData.scenario,
          language: validatedData.language,
        },
      }),
      {
        status: 200,
        headers,
      }
    );
  } catch (error) {
    // Zod验证错误
    if (error && typeof error === "object" && "issues" in error) {
      const zodError = error as { issues: Array<{ message: string }> };
      return errorResponse(
        `Validation error: ${zodError.issues.map((i) => i.message).join(", ")}`,
        400
      );
    }

    // 其他错误
    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
});
