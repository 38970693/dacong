/**
 * Auth Register Edge Function
 * 用户注册
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
import { registerSchema, validateInput } from "../_shared/schemas/auth_schemas.ts";
import { createRateLimiter, RateLimitPresets } from "../_shared/middleware/rate_limiter.ts";

initSentry({ functionName: "auth-register" });

const rateLimiter = createRateLimiter({
  ...RateLimitPresets.strict,
  message: "Too many registration attempts. Please try again later.",
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
      const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
      const supabase = createClient(supabaseUrl, supabaseKey);

      const body = await getRequestBody(req);
      const input = validateInput(registerSchema, body);

      const { data: existingUser } = await supabase
        .from("profiles")
        .select("username")
        .eq("username", input.username)
        .single();

      if (existingUser) {
        return errorResponse("Username already taken", 400);
      }

      const { data: authData, error: signUpError } = await supabase.auth.signUp({
        email: input.email,
        password: input.password,
        options: {
          data: {
            username: input.username,
          },
          emailRedirectTo: `${Deno.env.get("FRONTEND_URL")}/auth/verify`,
        },
      });

      if (signUpError) {
        return errorResponse(signUpError.message, 400);
      }

      if (!authData.user) {
        return errorResponse("Failed to create user", 500);
      }

      const { error: profileError } = await supabase
        .from("profiles")
        .insert({
          id: authData.user.id,
          username: input.username,
        });

      if (profileError) {
        console.error("Failed to create profile:", profileError);
      }

      return successResponse({
        user: {
          id: authData.user.id,
          email: authData.user.email,
          username: input.username,
        },
        message: "Registration successful. Please check your email to verify your account.",
      });
    },
    {
      functionName: "auth-register",
      captureErrors: true,
    }
  )
);
