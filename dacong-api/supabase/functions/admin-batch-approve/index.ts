/**
 * Admin Batch Approve Edge Function
 * 管理员批量审核内容
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
import { csrfMiddleware } from "../_shared/middleware/csrf.ts";

initSentry({ functionName: "admin-batch-approve" });

const batchApproveSchema = z.object({
  content_ids: z.array(z.string().uuid()).min(1).max(100),
  status: z.enum(["approved", "rejected"]),
  reason: z.string().optional(),
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
        requirePermission(user, Permissions.MODERATE_CONTENT);

        // CSRF 保护
        const csrfError = await csrfMiddleware(req, supabase, user.id);
        if (csrfError) return csrfError;

        const body = await getRequestBody(req);
        const { content_ids, status, reason } = batchApproveSchema.parse(body);

        const { data: updated, error: updateError } = await supabase
          .from("published_content")
          .update({
            status,
            moderation_reason: reason,
            moderated_by: user.id,
            moderated_at: new Date().toISOString(),
          })
          .in("id", content_ids)
          .select("id");

        if (updateError) {
          return errorResponse("Failed to update content", 500);
        }

        const { ipAddress, userAgent } = extractAuditInfo(req);
        await logAudit(supabase, {
          userId: user.id,
          action: AuditActions.ADMIN_BATCH_APPROVE,
          resource: AuditResources.CONTENT,
          ipAddress,
          userAgent,
          status: "success",
          details: {
            content_ids,
            status,
            reason,
            count: updated?.length || 0,
          },
        });

        return successResponse({
          message: `Successfully ${status} ${updated?.length || 0} items`,
          updated_count: updated?.length || 0,
        });
      } catch (error) {
        return errorResponse(
          error instanceof Error ? error.message : "Unauthorized",
          error instanceof Error && error.message.includes("permission") ? 403 : 401
        );
      }
    },
    {
      functionName: "admin-batch-approve",
      captureErrors: true,
    }
  )
);
