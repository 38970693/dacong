/**
 * Mark Notification Read Edge Function
 * 标记通知为已读的API端点
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  corsResponse,
  errorResponse,
  getRequestBody,
  successResponse,
  validateMethod,
} from "../_shared/utils/http.ts";

interface MarkReadRequest {
  notificationId: string;
}

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

    // 获取请求体
    const body = await getRequestBody<MarkReadRequest>(req);

    if (!body.notificationId) {
      return errorResponse("notificationId is required", 400);
    }

    // 验证通知是否属于当前用户
    const { data: notification, error: fetchError } = await supabase
      .from("notifications")
      .select("*")
      .eq("id", body.notificationId)
      .eq("user_id", user.id)
      .single();

    if (fetchError || !notification) {
      return errorResponse("Notification not found", 404);
    }

    // 标记为已读
    const { error: updateError } = await supabase
      .from("notifications")
      .update({ is_read: true })
      .eq("id", body.notificationId)
      .eq("user_id", user.id);

    if (updateError) {
      throw updateError;
    }

    return successResponse({
      success: true,
      message: "Notification marked as read",
    });
  } catch (error) {
    console.error("Error in mark-notification-read:", error);

    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
});
