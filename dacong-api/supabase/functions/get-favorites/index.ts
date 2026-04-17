/**
 * Get Favorites Edge Function
 * 获取用户收藏列表的API端点
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { Container } from "../_shared/core/Container.ts";
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

    const container = Container.getInstance(supabase);
    const favoriteService = container.getFavoriteService();

    // 获取查询参数
    const params = getQueryParams(req);
    const page = parseInt(params.get("page") || "1", 10);
    const pageSize = parseInt(params.get("pageSize") || "20", 10);

    // 验证分页参数
    if (page < 1 || pageSize < 1 || pageSize > 100) {
      return errorResponse("Invalid pagination parameters", 400);
    }

    // 获取收藏列表
    const result = await favoriteService.getUserFavorites(
      user.id,
      page,
      pageSize
    );

    // 获取收藏内容的详细信息
    const contentIds = result.favorites.map((f) => f.contentId);
    const { data: contents } = await supabase
      .from("published_content")
      .select("*")
      .in("id", contentIds);

    // 合并收藏和内容信息
    const favoritesWithContent = result.favorites.map((favorite) => {
      const content = contents?.find((c) => c.id === favorite.contentId);
      return {
        id: favorite.id,
        contentId: favorite.contentId,
        createdAt: favorite.createdAt.toISOString(),
        content: content
          ? {
              id: content.id,
              contentType: content.content_type,
              titleZh: content.title_zh,
              summaryZh: content.summary_zh,
              scenario: content.scenario,
              viewCount: content.view_count,
              helpfulCount: content.helpful_count,
              shareCount: content.share_count,
              publishedAt: content.published_at,
            }
          : null,
      };
    });

    return successResponse(
      {
        favorites: favoritesWithContent,
      },
      {
        total: result.total,
        page: result.page,
        pageSize: result.pageSize,
        totalPages: Math.ceil(result.total / result.pageSize),
      }
    );
  } catch (error) {
    console.error("Error in get-favorites:", error);

    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
});
