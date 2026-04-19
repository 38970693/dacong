/**
 * Admin Users Ban Edge Function
 * 管理员封禁用户
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import {
  corsResponse,
  errorResponse,
  getRequestBody,
  successResponse,
  validateMethod,
} from "../_shared/utils/http.ts";
import { initSentry, withSentry } from "../_shared/utils/sentry.ts";
import { requireAdmin, Permissions, requirePermission } from "../_shared/middleware/admin.ts";
import { logAudit, AuditActions, AuditResources, extractAuditInfo } from "../_shared/utils/audit.ts";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

initSentry({ functionName: "admin-users-ban" });

const banUserSchema = z.object({
  user_id: z.string().uuid("Invalid user ID format"),
  reason: z.string().min(1, "Ban reason is required").max(500),
  duration_days: z.number().int().min(1).max(365).optional(),
});

serve(
  withSentry(
    async (req) => {
      if (req.method === "OPTIONS") {
        return corsResponse();
      }

      validateMethod(req, ["POST"]);

      try {
        const { user, supabase } = await requireAdmin(req);
        requirePermission(user, Permissions.BAN_USERS);

        const body = await getRequestBody(req);
        const { user_id, reason, duration_days } = banUserSchema.parse(body);

        if (user_id === user.id) {
          return errorResponse("Cannot ban yourself", 400);
        }

        const { data: targetUser } = await supabase
          .from("user_roles")
          .select("role")
          .eq("user_id", user_id)
          .single();

        if (targetUser?.role === "admin") {
          return errorResponse("Cannot ban admin users", 403);
        }

        const banned_until = duration_days
          ? new Date(Date.now() + duration_days * 24 * 60 * 60 * 1000).toISOString()
          : null;

        const { error: updateError } = await supabase
          .from("user_roles")
          .update({
            role: "banned",
            banned_until,
            ban_reason: reason,
            is_active: false,
          })
          .eq("user_id", user_id);

        if (updateError) {
          return errorResponse("Failed to ban user", 500);
        }

        const { ipAddress, userAgent } = extractAuditInfo(req);
        await logAudit(supabase, {
          userId: user.id,
          action: AuditActions.USER_BAN,
          resource: AuditResources.USER,
          resourceId: user_id,
          ipAddress,
          userAgent,
          status: "success",
          details: {
            reason,
            duration_days,
            banned_until,
          },
        });

        return successResponse({
          message: "User banned successfully",
          banned_until,
        });
      } catch (error) {
        return errorResponse(
          error instanceof Error ? error.message : "Unauthorized",
          error instanceof Error && error.message.includes("permission") ? 403 : 401
        );
      }
    },
    {
      functionName: "admin-users-ban",
      captureErrors: true,
    }
  )
);
