/**
 * Record Share Request DTO
 */

import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

export const RecordShareRequestSchema = z.object({
  contentId: z.string().uuid("Invalid content ID format"),
  platform: z.enum([
    "system",
    "wechat",
    "weibo",
    "twitter",
    "facebook",
    "linkedin",
    "copy_link",
    "other",
  ]),
});

export type RecordShareRequest = z.infer<typeof RecordShareRequestSchema>;
