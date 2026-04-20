/**
 * CSRF Token Edge Function
 * 为客户端提供 CSRF Token
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  corsResponse,
  errorResponse,
  validateMethod,
} from "../_shared/utils/http.ts";
import { initSentry, withSentry } from "../_shared/utils/sentry.ts";
import {
  generateCsrfToken,
  generateCsrfCookieHeader,
  encodeToken,
  refreshCsrfToken,
  clearUserCsrfTokens,
} from "../_shared/middleware/csrf.ts";

initSentry({ functionName: "csrf-token" });

serve(
  withSentry(
    async (req) => {
      if (req.method === "OPTIONS") {
        return corsResponse();
      }

      const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
      const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;

      // GET: 获取新的 CSRF Token
      if (req.method === "GET") {
        const authHeader = req.headers.get("Authorization");

        // 未认证用户也可以获取 Token（用于登录等操作）
        if (!authHeader) {
          const csrfToken = generateCsrfToken();
          const cookieHeader = generateCsrfCookieHeader(csrfToken);
          const encodedToken = encodeToken(csrfToken);

          return new Response(
            JSON.stringify({
              success: true,
              data: {
                csrf_token: encodedToken,
                expires_in: 3600,
              },
            }),
            {
              status: 200,
              headers: {
                "Content-Type": "application/json",
                "Set-Cookie": cookieHeader,
              },
            }
          );
        }

        // 已认证用户：生成并存储到数据库
        const supabase = createClient(supabaseUrl, supabaseKey, {
          global: {
            headers: { Authorization: authHeader },
          },
        });

        const { data: { user }, error: authError } = await supabase.auth.getUser();

        if (authError || !user) {
          return errorResponse("Invalid or expired token", 401);
        }

        const csrfToken = await refreshCsrfToken(supabase, user.id, req);
        const cookieHeader = generateCsrfCookieHeader(csrfToken);
        const encodedToken = encodeToken(csrfToken);

        return new Response(
          JSON.stringify({
            success: true,
            data: {
              csrf_token: encodedToken,
              expires_in: 3600,
            },
          }),
          {
            status: 200,
            headers: {
              "Content-Type": "application/json",
              "Set-Cookie": cookieHeader,
            },
          }
        );
      }

      // POST: 刷新 CSRF Token
      if (req.method === "POST") {
        validateMethod(req, ["POST"]);

        const authHeader = req.headers.get("Authorization");
        if (!authHeader) {
          return errorResponse("Authentication required", 401);
        }

        const supabase = createClient(supabaseUrl, supabaseKey, {
          global: {
            headers: { Authorization: authHeader },
          },
        });

        const { data: { user }, error: authError } = await supabase.auth.getUser();

        if (authError || !user) {
          return errorResponse("Invalid or expired token", 401);
        }

        const csrfToken = await refreshCsrfToken(supabase, user.id, req);
        const cookieHeader = generateCsrfCookieHeader(csrfToken);
        const encodedToken = encodeToken(csrfToken);

        return new Response(
          JSON.stringify({
            success: true,
            data: {
              csrf_token: encodedToken,
              expires_in: 3600,
            },
          }),
          {
            status: 200,
            headers: {
              "Content-Type": "application/json",
              "Set-Cookie": cookieHeader,
            },
          }
        );
      }

      // DELETE: 清除所有 CSRF Token（用于登出）
      if (req.method === "DELETE") {
        validateMethod(req, ["DELETE"]);

        const authHeader = req.headers.get("Authorization");
        if (!authHeader) {
          return errorResponse("Authentication required", 401);
        }

        const supabase = createClient(supabaseUrl, supabaseKey, {
          global: {
            headers: { Authorization: authHeader },
          },
        });

        const { data: { user }, error: authError } = await supabase.auth.getUser();

        if (authError || !user) {
          return errorResponse("Invalid or expired token", 401);
        }

        await clearUserCsrfTokens(supabase, user.id);

        return new Response(
          JSON.stringify({
            success: true,
            data: {
              message: "CSRF tokens cleared",
            },
          }),
          {
            status: 200,
            headers: {
              "Content-Type": "application/json",
            },
          }
        );
      }

      return errorResponse("Method not allowed", 405);
    },
    {
      functionName: "csrf-token",
      captureErrors: true,
    }
  )
);
