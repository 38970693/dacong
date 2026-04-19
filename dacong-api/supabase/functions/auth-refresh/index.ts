/**
 * Auth Refresh Token Edge Function
 * 刷新访问令牌
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
import { refreshTokenSchema, validateInput } from "../_shared/schemas/auth_schemas.ts";

initSentry({ functionName: "auth-refresh" });

serve(
  withSentry(
    async (req) => {
      if (req.method === "OPTIONS") {
        return corsResponse();
      }

      validateMethod(req, ["POST"]);

      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;
      const supabase = createClient(supabaseUrl, supabaseKey);

      const body = await getRequestBody(req);
      const input = validateInput(refreshTokenSchema, body);

      const { data, error } = await supabase.auth.refreshSession({
        refresh_token: input.refresh_token,
      });

      if (error || !data.session) {
        return errorResponse("Invalid or expired refresh token", 401);
      }

      return successResponse({
        session: {
          access_token: data.session.access_token,
          refresh_token: data.session.refresh_token,
          expires_at: data.session.expires_at,
        },
      });
    },
    {
      functionName: "auth-refresh",
      captureErrors: true,
    }
  )
);
