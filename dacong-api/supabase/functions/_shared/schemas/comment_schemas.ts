/**
 * Comment Related Validation Schemas
 * 评论相关的验证 Schema
 */

import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

/**
 * 提交评论 Schema
 */
export const submitCommentSchema = z.object({
  content_id: z.string().uuid("Invalid content ID format"),
  parent_id: z.string().uuid("Invalid parent comment ID format").optional().nullable(),
  content: z.string()
    .min(1, "Comment cannot be empty")
    .max(1000, "Comment must not exceed 1000 characters")
    .transform((val) => val.trim()),
});

export type SubmitCommentInput = z.infer<typeof submitCommentSchema>;

/**
 * 点赞评论 Schema
 */
export const likeCommentSchema = z.object({
  comment_id: z.string().uuid("Invalid comment ID format"),
  action: z.enum(["like", "unlike"], {
    errorMap: () => ({ message: "Action must be 'like' or 'unlike'" }),
  }),
});

export type LikeCommentInput = z.infer<typeof likeCommentSchema>;

/**
 * 举报评论 Schema
 */
export const reportCommentSchema = z.object({
  comment_id: z.string().uuid("Invalid comment ID format"),
  reason: z.enum([
    "spam",
    "harassment",
    "hate_speech",
    "violence",
    "misinformation",
    "other",
  ], {
    errorMap: () => ({ message: "Invalid report reason" }),
  }),
  description: z.string()
    .max(500, "Description must not exceed 500 characters")
    .optional(),
});

export type ReportCommentInput = z.infer<typeof reportCommentSchema>;

/**
 * 获取评论列表 Schema
 */
export const getCommentsSchema = z.object({
  content_id: z.string().uuid("Invalid content ID format"),
  parent_id: z.string().uuid("Invalid parent comment ID format").optional().nullable(),
  page: z.number().int().min(1, "Page must be at least 1").default(1),
  limit: z.number().int().min(1).max(100, "Limit must be between 1 and 100").default(20),
  sort_by: z.enum(["created_at", "likes_count"]).optional().default("created_at"),
  sort_order: z.enum(["asc", "desc"]).optional().default("desc"),
});

export type GetCommentsInput = z.infer<typeof getCommentsSchema>;
