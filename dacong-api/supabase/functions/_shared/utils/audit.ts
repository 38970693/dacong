/**
 * Audit Logging Utilities
 * 审计日志工具函数
 */

import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export interface AuditLogParams {
  userId: string;
  action: string;
  resource: string;
  resourceId?: string;
  details?: Record<string, unknown>;
  ipAddress?: string;
  userAgent?: string;
  status?: "success" | "failure" | "error";
  errorMessage?: string;
}

/**
 * 记录审计日志
 */
export async function logAudit(
  supabase: SupabaseClient,
  params: AuditLogParams
): Promise<void> {
  const {
    userId,
    action,
    resource,
    resourceId,
    details = {},
    ipAddress,
    userAgent,
    status = "success",
    errorMessage,
  } = params;

  try {
    const { error } = await supabase.from("audit_logs").insert({
      user_id: userId,
      action,
      resource,
      resource_id: resourceId,
      details,
      ip_address: ipAddress,
      user_agent: userAgent,
      status,
      error_message: errorMessage,
    });

    if (error) {
      console.error("Failed to log audit:", error);
    }
  } catch (error) {
    console.error("Failed to log audit:", error);
  }
}

/**
 * 从请求中提取审计信息
 */
export function extractAuditInfo(req: Request): {
  ipAddress: string;
  userAgent: string;
} {
  const ipAddress =
    req.headers.get("x-forwarded-for")?.split(",")[0].trim() ||
    req.headers.get("x-real-ip") ||
    "unknown";

  const userAgent = req.headers.get("user-agent") || "unknown";

  return { ipAddress, userAgent };
}

/**
 * 审计日志包装器 - 自动记录函数执行
 */
export function withAudit<T>(
  supabase: SupabaseClient,
  userId: string,
  action: string,
  resource: string,
  req: Request,
  fn: () => Promise<T>
): Promise<T> {
  return fn()
    .then(async (result) => {
      const { ipAddress, userAgent } = extractAuditInfo(req);
      await logAudit(supabase, {
        userId,
        action,
        resource,
        ipAddress,
        userAgent,
        status: "success",
      });
      return result;
    })
    .catch(async (error) => {
      const { ipAddress, userAgent } = extractAuditInfo(req);
      await logAudit(supabase, {
        userId,
        action,
        resource,
        ipAddress,
        userAgent,
        status: "error",
        errorMessage: error instanceof Error ? error.message : String(error),
      });
      throw error;
    });
}

/**
 * 常用审计操作类型
 */
export const AuditActions = {
  // 用户操作
  USER_LOGIN: "user.login",
  USER_LOGOUT: "user.logout",
  USER_REGISTER: "user.register",
  USER_UPDATE: "user.update",
  USER_DELETE: "user.delete",
  USER_BAN: "user.ban",
  USER_UNBAN: "user.unban",

  // 内容操作
  CONTENT_CREATE: "content.create",
  CONTENT_UPDATE: "content.update",
  CONTENT_DELETE: "content.delete",
  CONTENT_APPROVE: "content.approve",
  CONTENT_REJECT: "content.reject",

  // 评论操作
  COMMENT_CREATE: "comment.create",
  COMMENT_UPDATE: "comment.update",
  COMMENT_DELETE: "comment.delete",
  COMMENT_MODERATE: "comment.moderate",

  // 管理操作
  ADMIN_BATCH_APPROVE: "admin.batch_approve",
  ADMIN_BATCH_DELETE: "admin.batch_delete",
  ADMIN_ROLE_CHANGE: "admin.role_change",
} as const;

/**
 * 资源类型
 */
export const AuditResources = {
  USER: "user",
  CONTENT: "content",
  COMMENT: "comment",
  FAVORITE: "favorite",
  NOTIFICATION: "notification",
  ROLE: "role",
} as const;
