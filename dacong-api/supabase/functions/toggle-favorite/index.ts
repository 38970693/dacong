/**
 * Toggle Favorite Edge Function
 * 切换收藏状态的API端点
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
import { withSentry, reportApiError, reportDatabaseError, setUser } from "../_shared/monitoring/sentry.ts";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

// 请求验证 Schema
const ToggleFavoriteRequestSchema = z.object({
  content_id: z.string().uuid(),
});

serve(withSentry(async (req) => {
      if (req.method === "OPTIONS") {
        return corsResponse();
      }

      validateMethod(req, ["POST"]);

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

      // 设置用户上下文到 Sentry
      setUser(user.id, { email: user.email });

      const body = await getRequestBody(req);
      const validatedData = ToggleFavoriteRequestSchema.parse(body);

      // 检查内容是否存在
      const { data: content, error: contentError } = await supabase
        .from("published_content")
        .select("id")
        .eq("id", validatedData.content_id)
        .single();

      if (contentError || !content) {
        if (contentError) {
          reportDatabaseError(contentError, {
            operation: "select",
            table: "published_content",
            extras: { content_id: validatedData.content_id },
          });
        }
        return errorResponse("Content not found", 404);
      }

      // 检查是否已收藏
      const { data: existingFavorite } = await supabase
        .from("favorites")
        .select("id")
        .eq("user_id", user.id)
        .eq("content_id", validatedData.content_id)
        .maybeSingle();

      if (existingFavorite) {
        // 已收藏，执行取消收藏
        const { error: deleteError } = await supabase
          .from("favorites")
          .delete()
          .eq("id", existingFavorite.id);

        if (deleteError) {
          reportDatabaseError(deleteError, {
            operation: "delete",
            table: "favorites",
            extras: { favorite_id: existingFavorite.id },
          });
          return errorResponse("Failed to remove favorite", 500);
        }

        return successResponse({
          is_favorited: false,
          message: "Favorite removed successfully",
        });
      } else {
        // 未收藏，执行添加收藏
        const { error: insertError } = await supabase
          .from("favorites")
          .insert({
            user_id: user.id,
            content_id: validatedData.content_id,
          });

        if (insertError) {
          reportDatabaseError(insertError, {
            operation: "insert",
            table: "favorites",
            extras: { user_id: user.id, content_id: validatedData.content_id },
          });
          return errorResponse("Failed to add favorite", 500);
        }

        return successResponse({
          is_favorited: true,
          message: "Favorite added successfully",
        });
      }
}, { functionName: "toggle-favorite", tags: { service: "favorites" } }));
