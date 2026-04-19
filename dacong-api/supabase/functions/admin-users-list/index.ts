/**
 * Admin Users List Edge Function
 * 管理员查看用户列表
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  corsResponse,
  errorResponse,
  getQueryParams,
  successResponse,
  validateMethod,
} from "../_shared/utils/http.ts";
import { initSentry, withSentry } from "../_shared/utils/sentry.ts";
import { requireAdmin, Permissions, requirePermission } from "../_shared/middleware/admin.ts";

initSentry({ functionName: "admin-users-list" });

serve(
  withSentry(
    async (req) => {
      if (req.method === "OPTIONS") {
        return corsResponse();
      }

      validateMethod(req, ["GET"]);

      try {
        const { user, supabase } = await requireAdmin(req);
        requirePermission(user, Permissions.VIEW_USERS);

        const params = getQueryParams(req);
        const page = parseInt(params.get("page") || "1");
        const limit = Math.min(parseInt(params.get("limit") || "20"), 100);
        const search = params.get("search") || "";
        const role = params.get("role") || "";
        const status = params.get("status") || "";
        const offset = (page - 1) * limit;

        let query = supabase
          .from("profiles")
          .select(
            `
            id,
            username,
            avatar_url,
            bio,
            created_at,
            user_roles!inner(role, is_active, banned_until, ban_reason)
          `,
            { count: "exact" }
          );

        if (search) {
          query = query.or(`username.ilike.%${search}%,email.ilike.%${search}%`);
        }

        if (role) {
          query = query.eq("user_roles.role", role);
        }

        if (status === "active") {
          query = query.eq("user_roles.is_active", true);
        } else if (status === "banned") {
          query = query.eq("user_roles.role", "banned");
        }

        const { data: users, error: usersError, count } = await query
          .order("created_at", { ascending: false })
          .range(offset, offset + limit - 1);

        if (usersError) {
          return errorResponse("Failed to fetch users", 500);
        }

        return successResponse(users, {
          total: count || 0,
          page,
          limit,
          total_pages: Math.ceil((count || 0) / limit),
        });
      } catch (error) {
        return errorResponse(
          error instanceof Error ? error.message : "Unauthorized",
          error instanceof Error && error.message.includes("permission") ? 403 : 401
        );
      }
    },
    {
      functionName: "admin-users-list",
      captureErrors: true,
    }
  )
);
