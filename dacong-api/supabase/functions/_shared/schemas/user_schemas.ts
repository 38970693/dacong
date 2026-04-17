/**
 * User Related Validation Schemas
 * 用户相关的验证 Schema
 */

import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

/**
 * 更新用户资料 Schema
 */
export const updateProfileSchema = z.object({
  username: z.string()
    .min(2, "Username must be at least 2 characters")
    .max(50, "Username must not exceed 50 characters")
    .regex(/^[a-zA-Z0-9_-]+$/, "Username can only contain letters, numbers, underscores and hyphens")
    .optional(),
  avatar_url: z.string()
    .url("Invalid avatar URL format")
    .optional(),
  bio: z.string()
    .max(200, "Bio must not exceed 200 characters")
    .optional(),
});

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;

/**
 * 追踪事件 Schema
 */
export const trackEventSchema = z.object({
  event_type: z.enum([
    "page_view",
    "content_view",
    "search",
    "feedback",
    "comment",
    "share",
    "click",
  ], {
    errorMap: () => ({ message: "Invalid event type" }),
  }),
  content_id: z.string().uuid("Invalid content ID format").optional(),
  metadata: z.record(z.unknown()).optional(),
});

export type TrackEventInput = z.infer<typeof trackEventSchema>;
