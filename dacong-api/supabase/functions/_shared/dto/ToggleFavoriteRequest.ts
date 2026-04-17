/**
 * Toggle Favorite Request DTO
 */

import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

export const ToggleFavoriteRequestSchema = z.object({
  contentId: z.string().uuid("Invalid content ID format"),
});

export type ToggleFavoriteRequest = z.infer<typeof ToggleFavoriteRequestSchema>;
