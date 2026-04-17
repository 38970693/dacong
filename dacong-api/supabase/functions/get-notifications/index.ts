/**
 * Get Notifications Edge Function
 * 获取用户通知列表的API端点
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

    // 获取查询参数
    const params = getQueryParams(req);
    const page = parseInt(params.get("page") || "1", 10);
    const pageSize = parseInt(params.get("pageSize") || "20", 10);
    const unreadOnly = params.get("unreadOnly") === "true";

    // 验证分页参数
    if (page < 1 || pageSize < 1 || pageSize > 100) {
      return errorResponse("Invalid pagination parameters", 400);
    }

    // 构建查询
    let query = supabase
      .from("notifications")
      .select("*", { count: "exact" })
      .eq("user_id", user.id);

    // 只查询未读通知
    if (unreadOnly) {
      query = query.eq("is_read", false);
    }

    // 分页和排序
    const { data: notifications, error, count } = await query
      .order("created_at", { ascending: false })
      .range((page - 1) * pageSize, page * pageSize - 1);

    if (error) {
      throw error;
    }

    // 获取未读数量
    const { count: unreadCount } = await supabase
      .from("notifications")
      .select("*", { count: "exact", head: true })
      .eq("user_id", user.id)
      .eq("is_read", false);

    return successResponse(
      {
        notifications: notifications?.map((n) => ({
          id: n.id,
          type: n.type,
          title: n.title,
          content: n.content,
          link: n.link,
          isRead: n.is_read,
          createdAt: n.created_at,
        })) || [],
        unreadCount: unreadCount || 0,
      },
      {
        total: count || 0,
        page,
        pageSize,
        totalPages: Math.ceil((count || 0) / pageSize),
      }
    );
  } catch (error) {
    console.error("Error in get-notifications:", error);

    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
});
