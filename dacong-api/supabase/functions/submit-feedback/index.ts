/**
 * Submit Feedback Edge Function
 * 提交用户反馈的API端点
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { Container } from "../_shared/core/Container.ts";
import { SubmitFeedbackRequestSchema } from "../_shared/dto/SubmitFeedbackRequest.ts";
import {
  corsResponse,
  errorResponse,
  getClientIp,
  getRequestBody,
  getUserAgent,
  successResponse,
  validateMethod,
} from "../_shared/utils/http.ts";
import { csrfMiddleware } from "../_shared/middleware/csrf.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return corsResponse();
  }

  try {
    validateMethod(req, ["POST"]);

    // CSRF 防护
    const csrfError = await csrfMiddleware(req);
    if (csrfError) return csrfError;

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const container = Container.getInstance(supabase);
    const feedbackService = container.getFeedbackService();

    // 获取请求体
    const body = await getRequestBody<{
      contentId: string;
      isHelpful: boolean;
      comment?: string;
    }>(req);

    // 验证请求数据
    const validatedData = SubmitFeedbackRequestSchema.parse(body);

    // 获取用户信息
    const authHeader = req.headers.get("Authorization");
    let userId: string | null = null;

    if (authHeader) {
      const {
        data: { user },
      } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""));
      userId = user?.id || null;
    }

    // 获取客户端信息
    const userAgent = getUserAgent(req);
    const ipAddress = getClientIp(req);

    // 提交反馈
    const result = await feedbackService.submitFeedback(
      validatedData.contentId,
      validatedData.isHelpful,
      userId,
      validatedData.comment || null,
      userAgent,
      ipAddress
    );

    if (!result.success) {
      return errorResponse(result.error || "Failed to submit feedback", 400);
    }

    return successResponse(
      {
        id: result.feedback!.id,
        content_id: result.feedback!.contentId,
        is_helpful: result.feedback!.isHelpful,
        created_at: result.feedback!.createdAt.toISOString(),
      },
      { message: "Feedback submitted successfully" }
    );
  } catch (error) {
    console.error("Error in submit-feedback:", error);

    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
});
