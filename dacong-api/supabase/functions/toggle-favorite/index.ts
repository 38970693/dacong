/**
 * Toggle Favorite Edge Function
 * 切换收藏状态的API端点
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { Container } from "../_shared/core/Container.ts";
import { ToggleFavoriteRequestSchema } from "../_shared/dto/ToggleFavoriteRequest.ts";
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

    // 获取请求体
    const body = await getRequestBody<{ contentId: string }>(req);

    // 验证请求数据
    const validatedData = ToggleFavoriteRequestSchema.parse(body);

    // 切换收藏状态
    const result = await favoriteService.toggleFavorite(
      user.id,
      validatedData.contentId
    );

    return successResponse({
      favorited: result.favorited,
      contentId: validatedData.contentId,
      ...(result.favorite && {
        favoriteId: result.favorite.id,
        createdAt: result.favorite.createdAt.toISOString(),
      }),
    });
  } catch (error) {
    console.error("Error in toggle-favorite:", error);

    if (error instanceof Error) {
      return errorResponse(error.message, 400);
    }

    return errorResponse("Internal server error", 500);
  }
});
