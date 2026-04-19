/**
 * Auth Reset Password Edge Function
 * 密码重置请求
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
import { resetPasswordRequestSchema, validateInput } from "../_shared/schemas/auth_schemas.ts";
import { createRateLimiter, RateLimitPresets } from "../_shared/middleware/rate_limiter.ts";

initSentry({ functionName: "auth-reset-password" });

const rateLimiter = createRateLimiter({
  ...RateLimitPresets.strict,
  message: "Too many password reset requests. Please try again later.",
});

serve(
  withSentry(
    async (req) => {
      if (req.method === "OPTIONS") {
        return corsResponse();
      }

      validateMethod(req, ["POST"]);

      const rateLimitResponse = await rateLimiter(req);
      if (rateLimitResponse) {
        return rateLimitResponse;
      }

      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;
      const supabase = createClient(supabaseUrl, supabaseKey);

      const body = await getRequestBody(req);
      const input = validateInput(resetPasswordRequestSchema, body);

      const { error } = await supabase.auth.resetPasswordForEmail(input.email, {
        redirectTo: `${Deno.env.get("FRONTEND_URL")}/auth/reset-password`,
      });

      if (error) {
        return errorResponse(error.message, 400);
      }

      return successResponse({
        message: "Password reset email sent. Please check your inbox.",
      });
    },
    {
      functionName: "auth-reset-password",
      captureErrors: true,
    }
  )
);
