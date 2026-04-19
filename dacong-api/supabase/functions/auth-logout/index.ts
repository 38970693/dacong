/**
 * Auth Logout Edge Function
 * 用户登出
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  corsResponse,
  errorResponse,
  successResponse,
  validateMethod,
} from "../_shared/utils/http.ts";
import { initSentry, withSentry } from "../_shared/utils/sentry.ts";
import { logAudit, AuditActions, AuditResources, extractAuditInfo } from "../_shared/utils/audit.ts";

initSentry({ functionName: "auth-logout" });

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

      const { error: signOutError } = await supabase.auth.signOut();

      if (signOutError) {
        return errorResponse(signOutError.message, 500);
      }

      const { ipAddress, userAgent } = extractAuditInfo(req);
      await logAudit(supabase, {
        userId: user.id,
        action: AuditActions.USER_LOGOUT,
        resource: AuditResources.USER,
        ipAddress,
        userAgent,
        status: "success",
      });

      return successResponse({
        message: "Logout successful",
      });
    },
    {
      functionName: "auth-logout",
      captureErrors: true,
    }
  )
);
