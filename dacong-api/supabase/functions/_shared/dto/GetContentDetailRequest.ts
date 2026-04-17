/**
 * Get Content Detail Request DTO
 * 获取内容详情请求DTO
 */

import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

export const GetContentDetailRequestSchema = z.object({
  id: z.string().uuid(),
  language: z.enum(["zh", "en"]).optional().default("zh"),
  incrementView: z.boolean().optional().default(true),
});

export type GetContentDetailRequest = z.infer<
  typeof GetContentDetailRequestSchema
>;
