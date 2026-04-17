/**
 * Cache Admin Endpoint
 * 缓存管理端点 - 用于预热、监控和管理缓存
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { Container } from "../_shared/core/Container.ts";
import { corsHeaders } from "../_shared/utils/cors.ts";

serve(async (req) => {
  // 处理 CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? ""
    );

    const container = Container.getInstance(supabaseClient);
    const cache = container.getCache();

    if (!cache) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Cache not available",
        }),
        {
          status: 503,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const url = new URL(req.url);
    const action = url.searchParams.get("action");

    switch (action) {
      case "stats":
        // 获取缓存统计
        const stats = await cache.getStats();
        return new Response(
          JSON.stringify({
            success: true,
            data: stats,
          }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );

      case "warmup":
        // 缓存预热
        await warmupCache(container, cache);
        return new Response(
          JSON.stringify({
            success: true,
            message: "Cache warmup completed",
          }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );

      case "flush":
        // 清空缓存
        await cache.flush();
        return new Response(
          JSON.stringify({
            success: true,
            message: "Cache flushed",
          }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );

      case "invalidate":
        // 失效指定模式的缓存
        const pattern = url.searchParams.get("pattern");
        if (!pattern) {
          return new Response(
            JSON.stringify({
              success: false,
              error: "Pattern parameter required",
            }),
            {
              status: 400,
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            }
          );
        }
        const count = await cache.delPattern(pattern);
        return new Response(
          JSON.stringify({
            success: true,
            message: `Invalidated ${count} keys`,
            data: { count },
          }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );

      default:
        return new Response(
          JSON.stringify({
            success: false,
            error: "Invalid action. Supported: stats, warmup, flush, invalidate",
          }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
    }
  } catch (error) {
    console.error("[cache-admin] Error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

/**
 * 缓存预热函数
 */
async function warmupCache(container: Container, cache: ICache) {
  console.log("[cache-admin] Starting cache warmup...");

  try {
    // 预热热门内容
    const contentService = container.getContentService();
    const hotContents = await contentService.getHotContents(50);
    await cache.set("content:hot:50", hotContents, { ttl: 300 });
    console.log("[cache-admin] ✓ Hot contents cached");

    // 预热推荐内容
    const recommendationService = container.getRecommendationService();
    const recommendations = await recommendationService.getRecommendations({
      limit: 20,
    });
    await cache.set("recommendation:top:20", recommendations, { ttl: 1800 });
    console.log("[cache-admin] ✓ Recommendations cached");

    console.log("[cache-admin] Cache warmup completed");
  } catch (error) {
    console.error("[cache-admin] Warmup error:", error);
    throw error;
  }
}
