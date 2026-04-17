/**
 * Mark All Read Edge Function
 * 标记所有通知为已读的API端点
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  corsResponse,
  errorResponse,
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

    // 获取用户信息（必须登录）
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return errorResponse("Authorization required", 401);
    }

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""));

    if (authError || !user) {
      return errorResponse("Invalid authorization", 401);
    }

    // 标记所有未读通知为已读
    const { error: updateError, count } = await supabase
      .from("notifications")
      .update({ is_read: true })
      .eq("user_id", user.id)
      .eq("is_read", false);

    if (updateError) {
      throw updateError;
    }

    return successResponse({
      success: true,
      message: "All notifications marked as read",
      updatedCount: count || 0,
    });
  } catch (error) {
    console.error("Error in mark-all-read:", error);

    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
});
