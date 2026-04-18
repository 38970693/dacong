/**
 * Get Favorites Edge Function
 * 获取用户收藏列表的API端点
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
import { initSentry, withSentry } from "../_shared/utils/sentry.ts";

// 初始化 Sentry
initSentry({
  functionName: "get-favorites",
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
      const authHeader = req.headers.get("Authorization");

      if (!authHeader) {
        return errorResponse("Missing authorization header", 401);
      }

      const supabase = createClient(supabaseUrl, supabaseKey, {
        global: {
          headers: { Authorization: authHeader },
        },
      });

      // 验证用户身份
      const {
        data: { user },
        error: authError,
      } = await supabase.auth.getUser();

      if (authError || !user) {
        return errorResponse("Unauthorized", 401);
      }

      // 获取分页参数
      const params = getQueryParams(req);
      const page = parseInt(params.get("page") || "1");
      const limit = Math.min(parseInt(params.get("limit") || "20"), 100);
      const language = params.get("language") || "zh";
      const offset = (page - 1) * limit;

      // 查询收藏列表（使用视图）
      const { data: favorites, error: favoritesError, count } = await supabase
        .from("user_favorites_detail")
        .select("*", { count: "exact" })
        .eq("user_id", user.id)
        .order("favorited_at", { ascending: false })
        .range(offset, offset + limit - 1);

      if (favoritesError) {
        return errorResponse("Failed to fetch favorites", 500);
      }

      // 格式化响应数据
      const formattedFavorites = (favorites || []).map((fav) => ({
        favorite_id: fav.favorite_id,
        content_id: fav.content_id,
        content_type: fav.content_type,
        title: language === "zh" ? fav.title_zh : fav.title_zh,
        summary: language === "zh" ? fav.summary_zh : fav.summary_zh,
        scenario: fav.scenario,
        view_count: fav.view_count,
        helpful_count: fav.helpful_count,
        share_count: fav.share_count,
        published_at: fav.published_at,
        favorited_at: fav.favorited_at,
      }));

      return successResponse(formattedFavorites, {
        total: count || 0,
        page,
        limit,
        total_pages: Math.ceil((count || 0) / limit),
      });
    },
    {
      functionName: "get-favorites",
      captureErrors: true,
    },
  ),
);
