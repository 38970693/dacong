/**
 * Content Related Validation Schemas
 * 内容相关的验证 Schema
 */

import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

/**
 * 提交反馈 Schema
 */
export const submitFeedbackSchema = z.object({
  content_id: z.string().uuid("Invalid content ID format"),
  feedback_type: z.enum(["helpful", "not_helpful"], {
    errorMap: () => ({ message: "Feedback type must be 'helpful' or 'not_helpful'" }),
  }),
  rating: z.number().int().min(1).max(5).optional(),
  comment: z.string().max(500, "Comment must not exceed 500 characters").optional(),
});

export type SubmitFeedbackInput = z.infer<typeof submitFeedbackSchema>;

/**
 * 搜索内容 Schema
 */
export const searchContentSchema = z.object({
  query: z.string()
    .min(1, "Search query cannot be empty")
    .max(100, "Search query must not exceed 100 characters")
    .transform((val) => val.trim()),
  scenario_id: z.string().uuid("Invalid scenario ID format").optional(),
  language: z.enum(["zh", "en"]).optional().default("zh"),
  page: z.number().int().min(1, "Page must be at least 1").default(1),
  limit: z.number().int().min(1).max(100, "Limit must be between 1 and 100").default(20),
  offset: z.number().int().min(0).optional().default(0),
});

export type SearchContentInput = z.infer<typeof searchContentSchema>;

/**
 * 获取内容详情 Schema
 */
export const getContentDetailSchema = z.object({
  content_id: z.string().uuid("Invalid content ID format"),
  language: z.enum(["zh", "en"]).optional().default("zh"),
});

export type GetContentDetailInput = z.infer<typeof getContentDetailSchema>;

/**
 * 获取推荐内容 Schema
 */
export const getRecommendationsSchema = z.object({
  content_id: z.string().uuid("Invalid content ID format").optional(),
  scenario_id: z.string().uuid("Invalid scenario ID format").optional(),
  language: z.enum(["zh", "en"]).optional().default("zh"),
  limit: z.number().int().min(1).max(50, "Limit must be between 1 and 50").default(10),
});

export type GetRecommendationsInput = z.infer<typeof getRecommendationsSchema>;
