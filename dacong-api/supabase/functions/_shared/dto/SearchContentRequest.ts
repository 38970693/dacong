/**
 * Search Content Request DTO
 * 搜索内容请求DTO
 */

import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

export const SearchContentRequestSchema = z.object({
  query: z.string().min(1).max(100),
  language: z.enum(["zh", "en"]).optional().default("zh"),
  limit: z.number().int().min(1).max(50).optional().default(20),
  offset: z.number().int().min(0).optional().default(0),
});

export type SearchContentRequest = z.infer<typeof SearchContentRequestSchema>;
