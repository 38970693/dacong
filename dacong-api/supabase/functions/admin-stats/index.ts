/**
 * Admin Stats Edge Function
 * 管理员查看统计数据
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  corsResponse,
  errorResponse,
  successResponse,
  validateMethod,
} from "../_shared/utils/http.ts";
import { initSentry, withSentry } from "../_shared/utils/sentry.ts";
import { requireAdmin, Permissions, requirePermission } from "../_shared/middleware/admin.ts";

initSentry({ functionName: "admin-stats" });

serve(
  withSentry(
    async (req) => {
      if (req.method === "OPTIONS") {
        return corsResponse();
      }

      validateMethod(req, ["GET"]);

      try {
        const { user, supabase } = await requireAdmin(req);
        requirePermission(user, Permissions.VIEW_STATS);

        const [
          { count: totalUsers },
          { count: activeUsers },
          { count: bannedUsers },
          { count: totalContent },
          { count: pendingContent },
          { count: totalComments },
          { count: totalFavorites },
        ] = await Promise.all([
          supabase.from("profiles").select("*", { count: "exact", head: true }),
          supabase.from("user_roles").select("*", { count: "exact", head: true }).eq("is_active", true),
          supabase.from("user_roles").select("*", { count: "exact", head: true }).eq("role", "banned"),
          supabase.from("published_content").select("*", { count: "exact", head: true }),
          supabase.from("published_content").select("*", { count: "exact", head: true }).eq("status", "pending"),
          supabase.from("comments").select("*", { count: "exact", head: true }),
          supabase.from("favorites").select("*", { count: "exact", head: true }),
        ]);

        const { data: recentUsers } = await supabase
          .from("profiles")
          .select("created_at")
          .gte("created_at", new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
          .select("*", { count: "exact", head: true });

        const { data: recentContent } = await supabase
          .from("published_content")
          .select("created_at")
          .gte("created_at", new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
          .select("*", { count: "exact", head: true });

        return successResponse({
          users: {
            total: totalUsers || 0,
            active: activeUsers || 0,
            banned: bannedUsers || 0,
            new_this_week: recentUsers?.length || 0,
          },
          content: {
            total: totalContent || 0,
            pending: pendingContent || 0,
            new_this_week: recentContent?.length || 0,
          },
          engagement: {
            total_comments: totalComments || 0,
            total_favorites: totalFavorites || 0,
          },
        });
      } catch (error) {
        return errorResponse(
          error instanceof Error ? error.message : "Unauthorized",
          error instanceof Error && error.message.includes("permission") ? 403 : 401
        );
      }
    },
    {
      functionName: "admin-stats",
      captureErrors: true,
    }
  )
);
