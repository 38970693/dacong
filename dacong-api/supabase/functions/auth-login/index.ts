/**
 * Auth Login Edge Function
 * 用户登录
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
import { loginSchema, validateInput } from "../_shared/schemas/auth_schemas.ts";
import { createRateLimiter, RateLimitPresets } from "../_shared/middleware/rate_limiter.ts";
import { logAudit, AuditActions, AuditResources, extractAuditInfo } from "../_shared/utils/audit.ts";
import { csrfMiddleware } from "../_shared/middleware/csrf.ts";

initSentry({ functionName: "auth-login" });

const rateLimiter = createRateLimiter({
  ...RateLimitPresets.standard,
  message: "Too many login attempts. Please try again later.",
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

      // CSRF 保护
      const csrfError = await csrfMiddleware(req);
      if (csrfError) return csrfError;

      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;
      const supabase = createClient(supabaseUrl, supabaseKey);

      const body = await getRequestBody(req);
      const input = validateInput(loginSchema, body);

      const { data: authData, error: signInError } = await supabase.auth.signInWithPassword({
        email: input.email,
        password: input.password,
      });

      if (signInError || !authData.user) {
        const { ipAddress, userAgent } = extractAuditInfo(req);
        await logAudit(supabase, {
          userId: "anonymous",
          action: AuditActions.USER_LOGIN,
          resource: AuditResources.USER,
          ipAddress,
          userAgent,
          status: "failure",
          errorMessage: "Invalid credentials",
          details: { email: input.email },
        });

        return errorResponse("Invalid email or password", 401);
      }

      const { data: userRole } = await supabase
        .from("user_roles")
        .select("role, is_active, banned_until")
        .eq("user_id", authData.user.id)
        .single();

      if (userRole?.role === "banned") {
        return errorResponse(
          userRole.banned_until
            ? `Account banned until ${new Date(userRole.banned_until).toLocaleDateString()}`
            : "Account permanently banned",
          403
        );
      }

      const { data: profile } = await supabase
        .from("profiles")
        .select("username, avatar_url")
        .eq("id", authData.user.id)
        .single();

      const { ipAddress, userAgent } = extractAuditInfo(req);
      await logAudit(supabase, {
        userId: authData.user.id,
        action: AuditActions.USER_LOGIN,
        resource: AuditResources.USER,
        ipAddress,
        userAgent,
        status: "success",
      });

      return successResponse({
        user: {
          id: authData.user.id,
          email: authData.user.email,
          username: profile?.username,
          avatar_url: profile?.avatar_url,
          role: userRole?.role || "user",
        },
        session: {
          access_token: authData.session?.access_token,
          refresh_token: authData.session?.refresh_token,
          expires_at: authData.session?.expires_at,
        },
      });
    },
    {
      functionName: "auth-login",
      captureErrors: true,
    }
  )
);
