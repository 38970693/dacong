/**
 * Favorites Add Edge Function
 * 添加收藏
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
import { initSentry, withSentry } from "../_shared/utils/sentry.ts";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

initSentry({ functionName: "favorites-add" });

const addFavoriteSchema = z.object({
  content_id: z.string().uuid("Invalid content ID format"),
});

serve(
  withSentry(
    async (req) => {
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

      const {
        data: { user },
        error: authError,
      } = await supabase.auth.getUser();

      if (authError || !user) {
        return errorResponse("Unauthorized", 401);
      }

      const body = await getRequestBody(req);
      const { content_id } = addFavoriteSchema.parse(body);

      const { data: content } = await supabase
        .from("published_content")
        .select("id")
        .eq("id", content_id)
        .single();

      if (!content) {
        return errorResponse("Content not found", 404);
      }

      const { data: existing } = await supabase
        .from("favorites")
        .select("id")
        .eq("user_id", user.id)
        .eq("content_id", content_id)
        .single();

      if (existing) {
        return errorResponse("Content already favorited", 400);
      }

      const { data: favorite, error: insertError } = await supabase
        .from("favorites")
        .insert({
          user_id: user.id,
          content_id,
        })
        .select()
        .single();

      if (insertError) {
        return errorResponse("Failed to add favorite", 500);
      }

      return successResponse({
        favorite_id: favorite.id,
        content_id: favorite.content_id,
        created_at: favorite.created_at,
        message: "Content added to favorites",
      });
    },
    {
      functionName: "favorites-add",
      captureErrors: true,
    }
  )
);
