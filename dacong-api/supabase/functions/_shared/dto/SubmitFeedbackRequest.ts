/**
 * Submit Feedback Request DTO
 * 提交反馈请求DTO
 */

import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

export const SubmitFeedbackRequestSchema = z.object({
  contentId: z.string().uuid(),
  isHelpful: z.boolean(),
  comment: z.string().max(500).optional(),
});

export type SubmitFeedbackRequest = z.infer<
  typeof SubmitFeedbackRequestSchema
>;
