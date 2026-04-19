/**
 * Admin Batch Delete Edge Function
 * 管理员批量删除内容
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

initSentry({ functionName: "admin-batch-delete" });

const batchDeleteSchema = z.object({
  resource_type: z.enum(["content", "comment"]),
  resource_ids: z.array(z.string().uuid()).min(1).max(100),
  reason: z.string().min(1, "Deletion reason is required"),
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
        requirePermission(user, Permissions.DELETE_CONTENT);

        const body = await getRequestBody(req);
        const { resource_type, resource_ids, reason } = batchDeleteSchema.parse(body);

        const tableName = resource_type === "content" ? "published_content" : "comments";

        const { data: deleted, error: deleteError } = await supabase
          .from(tableName)
          .delete()
          .in("id", resource_ids)
          .select("id");

        if (deleteError) {
          return errorResponse(`Failed to delete ${resource_type}`, 500);
        }

        const { ipAddress, userAgent } = extractAuditInfo(req);
        await logAudit(supabase, {
          userId: user.id,
          action: AuditActions.ADMIN_BATCH_DELETE,
          resource: resource_type === "content" ? AuditResources.CONTENT : AuditResources.COMMENT,
          ipAddress,
          userAgent,
          status: "success",
          details: {
            resource_type,
            resource_ids,
            reason,
            count: deleted?.length || 0,
          },
        });

        return successResponse({
          message: `Successfully deleted ${deleted?.length || 0} ${resource_type}(s)`,
          deleted_count: deleted?.length || 0,
        });
      } catch (error) {
        return errorResponse(
          error instanceof Error ? error.message : "Unauthorized",
          error instanceof Error && error.message.includes("permission") ? 403 : 401
        );
      }
    },
    {
      functionName: "admin-batch-delete",
      captureErrors: true,
    }
  )
);
