/**
 * CSRF 中间件集成示例
 *
 * 本文件展示如何在各个端点中集成 CSRF 保护
 */

// ============================================
// 示例 1: 认证端点（登录、注册等）
// ============================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { csrfMiddleware } from "../_shared/middleware/csrf.ts";

serve(async (req) => {
  // CSRF 验证（对于 POST/PUT/DELETE/PATCH 请求）
  const csrfError = await csrfMiddleware(req);
  if (csrfError) return csrfError;

  // 业务逻辑
  // ...
});

// ============================================
// 示例 2: 需要认证的端点（带用户验证）
// ============================================

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    {
      global: {
        headers: { Authorization: req.headers.get("Authorization") || "" },
      },
    }
  );

  // 获取当前用户
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  // CSRF 验证（带用户 ID 验证）
  const csrfError = await csrfMiddleware(req, supabase, user.id);
  if (csrfError) return csrfError;

  // 业务逻辑
  // ...
});

// ============================================
// 示例 3: 管理员端点（带权限验证）
// ============================================

import { requireAdmin } from "../_shared/middleware/admin.ts";

serve(async (req) => {
  // 验证管理员身份
  const { user, supabase } = await requireAdmin(req);

  // CSRF 验证（带用户 ID 验证）
  const csrfError = await csrfMiddleware(req, supabase, user.id);
  if (csrfError) return csrfError;

  // 业务逻辑
  // ...
});

// ============================================
// 需要集成 CSRF 保护的端点列表
// ============================================

/**
 * 认证相关（所有 POST 请求）:
 * - auth-register
 * - auth-login
 * - auth-logout
 * - auth-change-password
 * - auth-reset-password
 *
 * 内容管理（所有 POST/PUT/DELETE 请求）:
 * - admin-content-management
 * - admin-batch-approve
 * - admin-batch-delete
 *
 * 用户管理（所有 POST/PUT/DELETE 请求）:
 * - admin-user-management
 * - admin-users-ban
 * - admin-users-unban
 *
 * 评论管理（所有 POST/PUT/DELETE 请求）:
 * - admin-comment-moderation
 *
 * 其他状态变更操作:
 * - batch-update-profiles
 * - 所有涉及数据修改的端点
 */
