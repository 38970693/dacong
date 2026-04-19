/**
 * Admin Audit Logs Edge Function
 * 管理员查看审计日志
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

initSentry({ functionName: "admin-audit-logs" });

serve(
  withSentry(
    async (req) => {
      if (req.method === "OPTIONS") {
        return corsResponse();
      }

      validateMethod(req, ["GET"]);

      try {
        const { user, supabase } = await requireAdmin(req);
        requirePermission(user, Permissions.VIEW_AUDIT_LOGS);

        const params = getQueryParams(req);
        const page = parseInt(params.get("page") || "1");
        const limit = Math.min(parseInt(params.get("limit") || "50"), 200);
        const action = params.get("action") || "";
        const resource = params.get("resource") || "";
        const user_id = params.get("user_id") || "";
        const status = params.get("status") || "";
        const offset = (page - 1) * limit;

        let query = supabase
          .from("audit_logs")
          .select("*", { count: "exact" });

        if (action) {
          query = query.eq("action", action);
        }

        if (resource) {
          query = query.eq("resource", resource);
        }

        if (user_id) {
          query = query.eq("user_id", user_id);
        }

        if (status) {
          query = query.eq("status", status);
        }

        const { data: logs, error: logsError, count } = await query
          .order("created_at", { ascending: false })
          .range(offset, offset + limit - 1);

        if (logsError) {
          return errorResponse("Failed to fetch audit logs", 500);
        }

        return successResponse(logs, {
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
      functionName: "admin-audit-logs",
      captureErrors: true,
    }
  )
);
