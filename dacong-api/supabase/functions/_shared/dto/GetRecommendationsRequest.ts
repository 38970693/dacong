/**
 * Get Recommendations Request DTO
 * 获取推荐请求DTO
 */

import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

export const GetRecommendationsRequestSchema = z.object({
  scenario: z.enum([
    "coding",
    "video",
    "image",
    "chat",
    "writing",
    "data",
  ]),
  language: z.enum(["zh", "en"]).optional().default("zh"),
  limit: z.number().int().min(1).max(50).optional().default(20),
});

export type GetRecommendationsRequest = z.infer<
  typeof GetRecommendationsRequestSchema
>;
