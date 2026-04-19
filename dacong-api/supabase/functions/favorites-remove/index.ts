/**
 * Favorites Remove Edge Function
 * 取消收藏
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  corsResponse,
  errorResponse,
  successResponse,
  validateMethod,
} from "../_shared/utils/http.ts";
import { initSentry, withSentry } from "../_shared/utils/sentry.ts";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

initSentry({ functionName: "favorites-remove" });

const removeFavoriteSchema = z.object({
  content_id: z.string().uuid("Invalid content ID format"),
});

serve(
  withSentry(
    async (req) => {
      if (req.method === "OPTIONS") {
        return corsResponse();
      }

      validateMethod(req, ["DELETE"]);

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

      const url = new URL(req.url);
      const content_id = url.searchParams.get("content_id");

      if (!content_id) {
        return errorResponse("Missing content_id parameter", 400);
      }

      removeFavoriteSchema.parse({ content_id });

      const { error: deleteError } = await supabase
        .from("favorites")
        .delete()
        .eq("user_id", user.id)
        .eq("content_id", content_id);

      if (deleteError) {
        return errorResponse("Failed to remove favorite", 500);
      }

      return successResponse({
        message: "Content removed from favorites",
      });
    },
    {
      functionName: "favorites-remove",
      captureErrors: true,
    }
  )
);
