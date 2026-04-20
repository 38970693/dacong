/**
 * Query and Pagination Validation Schemas
 * 查询和分页相关的验证 Schema
 */

import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

/**
 * 分页参数 Schema
 */
export const paginationSchema = z.object({
  page: z.number().int().min(1, "Page must be at least 1").default(1),
  limit: z.number().int().min(1).max(100, "Limit must be between 1 and 100").default(20),
  offset: z.number().int().min(0, "Offset must be non-negative").optional(),
});

export type PaginationInput = z.infer<typeof paginationSchema>;

/**
 * 排序参数 Schema
 */
export const sortSchema = z.object({
  sort_by: z.string()
    .min(1, "Sort field cannot be empty")
    .max(50, "Sort field name too long")
    .regex(/^[a-zA-Z_][a-zA-Z0-9_]*$/, "Invalid sort field name"),
  sort_order: z.enum(["asc", "desc"], {
    errorMap: () => ({ message: "Sort order must be 'asc' or 'desc'" }),
  }).default("desc"),
});

export type SortInput = z.infer<typeof sortSchema>;

/**
 * 搜索参数 Schema
 */
export const searchSchema = z.object({
  query: z.string()
    .min(1, "Search query cannot be empty")
    .max(200, "Search query must not exceed 200 characters")
    .transform((val) => val.trim()),
  filters: z.record(z.string(), z.unknown()).optional(),
});

export type SearchInput = z.infer<typeof searchSchema>;

/**
 * 日期范围 Schema
 */
export const dateRangeSchema = z.object({
  start_date: z.string().datetime("Invalid start date format").optional(),
  end_date: z.string().datetime("Invalid end date format").optional(),
}).refine(
  (data) => {
    if (data.start_date && data.end_date) {
      return new Date(data.start_date) <= new Date(data.end_date);
    }
    return true;
  },
  { message: "Start date must be before or equal to end date" }
);

export type DateRangeInput = z.infer<typeof dateRangeSchema>;

/**
 * ID 列表 Schema
 */
export const idListSchema = z.object({
  ids: z.array(z.string().uuid("Invalid ID format"))
    .min(1, "At least one ID is required")
    .max(100, "Cannot process more than 100 IDs at once"),
});

export type IdListInput = z.infer<typeof idListSchema>;

/**
 * UUID 参数 Schema
 */
export const uuidParamSchema = z.object({
  id: z.string().uuid("Invalid UUID format"),
});

export type UuidParamInput = z.infer<typeof uuidParamSchema>;

/**
 * 语言参数 Schema
 */
export const languageSchema = z.object({
  language: z.enum(["zh", "en"], {
    errorMap: () => ({ message: "Language must be 'zh' or 'en'" }),
  }).default("zh"),
});

export type LanguageInput = z.infer<typeof languageSchema>;

/**
 * 完整查询参数 Schema (分页 + 排序 + 搜索)
 */
export const fullQuerySchema = paginationSchema
  .merge(sortSchema.partial())
  .merge(searchSchema.partial());

export type FullQueryInput = z.infer<typeof fullQuerySchema>;
