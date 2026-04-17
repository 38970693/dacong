/**
 * Admin Related Validation Schemas
 * 管理员相关的验证 Schema
 */

import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

/**
 * 审核内容 Schema
 */
export const reviewContentSchema = z.object({
  content_ids: z.array(z.string().uuid("Invalid content ID format"))
    .min(1, "At least one content ID is required")
    .max(100, "Cannot review more than 100 items at once"),
  action: z.enum(["approve", "reject"], {
    errorMap: () => ({ message: "Action must be 'approve' or 'reject'" }),
  }),
  reason: z.string()
    .max(200, "Reason must not exceed 200 characters")
    .optional(),
});

export type ReviewContentInput = z.infer<typeof reviewContentSchema>;

/**
 * 编辑内容 Schema
 */
export const editContentSchema = z.object({
  content_id: z.string().uuid("Invalid content ID format"),
  title: z.string()
    .min(1, "Title cannot be empty")
    .max(200, "Title must not exceed 200 characters")
    .optional(),
  content: z.string()
    .min(1, "Content cannot be empty")
    .max(10000, "Content must not exceed 10000 characters")
    .optional(),
  topic_id: z.string().uuid("Invalid topic ID format").optional(),
});

export type EditContentInput = z.infer<typeof editContentSchema>;

/**
 * 删除内容 Schema
 */
export const deleteContentSchema = z.object({
  content_ids: z.array(z.string().uuid("Invalid content ID format"))
    .min(1, "At least one content ID is required")
    .max(100, "Cannot delete more than 100 items at once"),
});

export type DeleteContentInput = z.infer<typeof deleteContentSchema>;

/**
 * 获取内容列表 Schema (查询参数)
 */
export const getContentListSchema = z.object({
  status: z.enum(["all", "pending", "passed", "flagged"]).optional().default("pending"),
  page: z.number().int().min(1, "Page must be at least 1").default(1),
  limit: z.number().int().min(1).max(100, "Limit must be between 1 and 100").default(20),
  search: z.string().max(100, "Search query must not exceed 100 characters").optional().default(""),
  sort_by: z.enum(["created_at", "updated_at", "title"]).optional().default("created_at"),
  sort_order: z.enum(["asc", "desc"]).optional().default("desc"),
});

export type GetContentListInput = z.infer<typeof getContentListSchema>;

/**
 * 审核评论 Schema
 */
export const moderateCommentSchema = z.object({
  comment_ids: z.array(z.string().uuid("Invalid comment ID format"))
    .min(1, "At least one comment ID is required")
    .max(100, "Cannot moderate more than 100 items at once"),
  action: z.enum(["approve", "reject", "delete"], {
    errorMap: () => ({ message: "Action must be 'approve', 'reject', or 'delete'" }),
  }),
  reason: z.string()
    .max(200, "Reason must not exceed 200 characters")
    .optional(),
});

export type ModerateCommentInput = z.infer<typeof moderateCommentSchema>;

/**
 * 用户管理 Schema
 */
export const manageUserSchema = z.object({
  user_id: z.string().uuid("Invalid user ID format"),
  action: z.enum(["ban", "unban", "warn", "set_role"], {
    errorMap: () => ({ message: "Invalid action" }),
  }),
  reason: z.string()
    .max(200, "Reason must not exceed 200 characters")
    .optional(),
  role: z.enum(["user", "moderator", "admin"]).optional(),
  duration_days: z.number().int().min(1).max(365).optional(),
});

export type ManageUserInput = z.infer<typeof manageUserSchema>;
