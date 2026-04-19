/**
 * Enhanced Admin Middleware
 * 增强的管理员认证和权限控制中间件
 */

import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export interface AdminUser {
  id: string;
  email: string;
  role: "admin" | "moderator" | "user";
  permissions: Record<string, boolean>;
  is_active: boolean;
}

export interface AuthContext {
  user: AdminUser;
  supabase: SupabaseClient;
}

/**
 * 验证用户身份（任何已登录用户）
 */
export async function requireAuth(req: Request): Promise<AuthContext> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    throw new Error("Missing authorization header");
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    {
      global: {
        headers: { Authorization: authHeader },
      },
    }
  );

  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser();

  if (authError || !user) {
    throw new Error("Invalid or expired token");
  }

  const { data: userRole, error: roleError } = await supabase
    .from("user_roles")
    .select("role, permissions, is_active")
    .eq("user_id", user.id)
    .single();

  if (roleError || !userRole) {
    throw new Error("User role not found");
  }

  if (!userRole.is_active) {
    throw new Error("User account is inactive");
  }

  return {
    user: {
      id: user.id,
      email: user.email!,
      role: userRole.role,
      permissions: userRole.permissions || {},
      is_active: userRole.is_active,
    },
    supabase,
  };
}

/**
 * 验证管理员身份（admin 或 moderator）
 */
export async function requireAdmin(req: Request): Promise<AuthContext> {
  const context = await requireAuth(req);

  if (context.user.role !== "admin" && context.user.role !== "moderator") {
    throw new Error("Admin or moderator role required");
  }

  return context;
}

/**
 * 验证超级管理员身份（仅 admin）
 */
export async function requireSuperAdmin(req: Request): Promise<AuthContext> {
  const context = await requireAuth(req);

  if (context.user.role !== "admin") {
    throw new Error("Admin role required");
  }

  return context;
}

/**
 * 检查特定权限
 */
export function requirePermission(user: AdminUser, permission: string): void {
  if (user.role === "admin") {
    return;
  }

  if (user.role === "moderator") {
    const moderatorPermissions = [
      "view_users",
      "view_content",
      "moderate_content",
      "moderate_comments",
      "view_audit_logs",
    ];

    if (!moderatorPermissions.includes(permission)) {
      throw new Error(`Insufficient permissions: ${permission}`);
    }
    return;
  }

  if (user.permissions[permission] !== true) {
    throw new Error(`Missing permission: ${permission}`);
  }
}

/**
 * 权限常量
 */
export const Permissions = {
  // 用户管理
  VIEW_USERS: "view_users",
  MANAGE_USERS: "manage_users",
  BAN_USERS: "ban_users",
  CHANGE_ROLES: "change_roles",

  // 内容管理
  VIEW_CONTENT: "view_content",
  MANAGE_CONTENT: "manage_content",
  MODERATE_CONTENT: "moderate_content",
  DELETE_CONTENT: "delete_content",

  // 评论管理
  VIEW_COMMENTS: "view_comments",
  MODERATE_COMMENTS: "moderate_comments",
  DELETE_COMMENTS: "delete_comments",

  // 审计日志
  VIEW_AUDIT_LOGS: "view_audit_logs",

  // 系统管理
  MANAGE_SYSTEM: "manage_system",
  VIEW_STATS: "view_stats",
} as const;

/**
 * 角色权限映射
 */
export const RolePermissions: Record<string, string[]> = {
  admin: Object.values(Permissions),
  moderator: [
    Permissions.VIEW_USERS,
    Permissions.VIEW_CONTENT,
    Permissions.MODERATE_CONTENT,
    Permissions.VIEW_COMMENTS,
    Permissions.MODERATE_COMMENTS,
    Permissions.DELETE_COMMENTS,
    Permissions.VIEW_AUDIT_LOGS,
    Permissions.VIEW_STATS,
  ],
  user: [],
};

/**
 * 检查用户是否有权限
 */
export function hasPermission(user: AdminUser, permission: string): boolean {
  if (user.role === "admin") {
    return true;
  }

  const rolePermissions = RolePermissions[user.role] || [];
  if (rolePermissions.includes(permission)) {
    return true;
  }

  return user.permissions[permission] === true;
}
