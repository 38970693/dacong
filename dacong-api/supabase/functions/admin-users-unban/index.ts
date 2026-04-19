/**
 * Admin Users Unban Edge Function
 * 管理员解封用户
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

initSentry({ functionName: "admin-users-unban" });

const unbanUserSchema = z.object({
  user_id: z.string().uuid("Invalid user ID format"),
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
        const { user_id } = unbanUserSchema.parse(body);

        const { error: updateError } = await supabase
          .from("user_roles")
          .update({
            role: "user",
            banned_until: null,
            ban_reason: null,
            is_active: true,
          })
          .eq("user_id", user_id);

        if (updateError) {
          return errorResponse("Failed to unban user", 500);
        }

        const { ipAddress, userAgent } = extractAuditInfo(req);
        await logAudit(supabase, {
          userId: user.id,
          action: AuditActions.USER_UNBAN,
          resource: AuditResources.USER,
          resourceId: user_id,
          ipAddress,
          userAgent,
          status: "success",
        });

        return successResponse({
          message: "User unbanned successfully",
        });
      } catch (error) {
        return errorResponse(
          error instanceof Error ? error.message : "Unauthorized",
          error instanceof Error && error.message.includes("permission") ? 403 : 401
        );
      }
    },
    {
      functionName: "admin-users-unban",
      captureErrors: true,
    }
  )
);
