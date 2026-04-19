/**
 * Favorites Check Edge Function
 * 检查是否已收藏
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

initSentry({ functionName: "favorites-check" });

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

      const {
        data: { user },
        error: authError,
      } = await supabase.auth.getUser();

      if (authError || !user) {
        return errorResponse("Unauthorized", 401);
      }

      const params = getQueryParams(req);
      const content_id = params.get("content_id");

      if (!content_id) {
        return errorResponse("Missing content_id parameter", 400);
      }

      const { data: favorite } = await supabase
        .from("favorites")
        .select("id, created_at")
        .eq("user_id", user.id)
        .eq("content_id", content_id)
        .single();

      return successResponse({
        is_favorited: !!favorite,
        favorite_id: favorite?.id || null,
        favorited_at: favorite?.created_at || null,
      });
    },
    {
      functionName: "favorites-check",
      captureErrors: true,
    }
  )
);
