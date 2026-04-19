/**
 * Auth Verify Email Edge Function
 * 邮箱验证
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  corsResponse,
  errorResponse,
  getQueryParams,
  successResponse,
  validateMethod,
} from "../_shared/utils/http.ts";
import { initSentry, withSentry } from "../_shared/utils/sentry.ts";

initSentry({ functionName: "auth-verify-email" });

serve(
  withSentry(
    async (req) => {
      if (req.method === "OPTIONS") {
        return corsResponse();
      }

      validateMethod(req, ["GET"]);

      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;
      const supabase = createClient(supabaseUrl, supabaseKey);

      const params = getQueryParams(req);
      const token = params.get("token");
      const type = params.get("type") || "signup";

      if (!token) {
        return errorResponse("Missing verification token", 400);
      }

      const { data, error } = await supabase.auth.verifyOtp({
        token_hash: token,
        type: type as "signup" | "email_change",
      });

      if (error) {
        return errorResponse(error.message, 400);
      }

      return successResponse({
        message: "Email verified successfully",
        user: {
          id: data.user?.id,
          email: data.user?.email,
        },
      });
    },
    {
      functionName: "auth-verify-email",
      captureErrors: true,
    }
  )
);
