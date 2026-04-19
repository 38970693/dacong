/**
 * Auth Change Password Edge Function
 * 修改密码（需要登录）
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
import { changePasswordSchema, validateInput } from "../_shared/schemas/auth_schemas.ts";
import { logAudit, AuditActions, AuditResources, extractAuditInfo } from "../_shared/utils/audit.ts";

initSentry({ functionName: "auth-change-password" });

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
      const input = validateInput(changePasswordSchema, body);

      const { error: verifyError } = await supabase.auth.signInWithPassword({
        email: user.email!,
        password: input.old_password,
      });

      if (verifyError) {
        return errorResponse("Current password is incorrect", 400);
      }

      const { error: updateError } = await supabase.auth.updateUser({
        password: input.new_password,
      });

      if (updateError) {
        return errorResponse(updateError.message, 400);
      }

      const { ipAddress, userAgent } = extractAuditInfo(req);
      await logAudit(supabase, {
        userId: user.id,
        action: AuditActions.USER_UPDATE,
        resource: AuditResources.USER,
        ipAddress,
        userAgent,
        status: "success",
        details: { action: "password_change" },
      });

      return successResponse({
        message: "Password changed successfully",
      });
    },
    {
      functionName: "auth-change-password",
      captureErrors: true,
    }
  )
);
