/**
 * Record Share Edge Function
 * 记录内容分享的API端点
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { Container } from "../_shared/core/Container.ts";
import { RecordShareRequestSchema } from "../_shared/dto/RecordShareRequest.ts";
import {
  corsResponse,
  errorResponse,
  getRequestBody,
  successResponse,
  validateMethod,
} from "../_shared/utils/http.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return corsResponse();
  }

  try {
    validateMethod(req, ["POST"]);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 获取用户信息（可选，支持匿名分享）
    const authHeader = req.headers.get("Authorization");
    let userId: string | null = null;

    if (authHeader) {
      const {
        data: { user },
      } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""));
      userId = user?.id || null;
    }

    const container = Container.getInstance(supabase);
    const shareService = container.getShareService();

    // 获取请求体
    const body = await getRequestBody<{
      contentId: string;
      platform: string;
    }>(req);

    // 验证请求数据
    const validatedData = RecordShareRequestSchema.parse(body);

    // 记录分享
    const share = await shareService.recordShare(
      validatedData.contentId,
      validatedData.platform,
      userId
    );

    return successResponse({
      id: share.id,
      contentId: share.contentId,
      platform: share.platform,
      createdAt: share.createdAt.toISOString(),
    });
  } catch (error) {
    console.error("Error in record-share:", error);

    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
});
