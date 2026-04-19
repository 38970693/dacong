/**
 * Auth Validation Schemas
 * 认证相关的数据验证模式
 */

import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

/**
 * 用户注册 Schema
 */
export const registerSchema = z.object({
  email: z.string().email("Invalid email format"),
  password: z
    .string()
    .min(8, "Password must be at least 8 characters")
    .max(128, "Password must be less than 128 characters")
    .regex(
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
      "Password must contain at least one uppercase letter, one lowercase letter, and one number"
    ),
  username: z
    .string()
    .min(3, "Username must be at least 3 characters")
    .max(30, "Username must be less than 30 characters")
    .regex(/^[a-zA-Z0-9_-]+$/, "Username can only contain letters, numbers, underscores, and hyphens"),
});

export type RegisterInput = z.infer<typeof registerSchema>;

/**
 * 用户登录 Schema
 */
export const loginSchema = z.object({
  email: z.string().email("Invalid email format"),
  password: z.string().min(1, "Password is required"),
});

export type LoginInput = z.infer<typeof loginSchema>;

/**
 * 刷新 Token Schema
 */
export const refreshTokenSchema = z.object({
  refresh_token: z.string().min(1, "Refresh token is required"),
});

export type RefreshTokenInput = z.infer<typeof refreshTokenSchema>;

/**
 * 密码重置请求 Schema
 */
export const resetPasswordRequestSchema = z.object({
  email: z.string().email("Invalid email format"),
});

export type ResetPasswordRequestInput = z.infer<typeof resetPasswordRequestSchema>;

/**
 * 密码重置确认 Schema
 */
export const resetPasswordConfirmSchema = z.object({
  token: z.string().min(1, "Token is required"),
  password: z
    .string()
    .min(8, "Password must be at least 8 characters")
    .max(128, "Password must be less than 128 characters")
    .regex(
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
      "Password must contain at least one uppercase letter, one lowercase letter, and one number"
    ),
});

export type ResetPasswordConfirmInput = z.infer<typeof resetPasswordConfirmSchema>;

/**
 * 修改密码 Schema
 */
export const changePasswordSchema = z.object({
  old_password: z.string().min(1, "Old password is required"),
  new_password: z
    .string()
    .min(8, "Password must be at least 8 characters")
    .max(128, "Password must be less than 128 characters")
    .regex(
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
      "Password must contain at least one uppercase letter, one lowercase letter, and one number"
    ),
});

export type ChangePasswordInput = z.infer<typeof changePasswordSchema>;

/**
 * 邮箱验证 Schema
 */
export const verifyEmailSchema = z.object({
  token: z.string().min(1, "Token is required"),
  type: z.enum(["signup", "email_change"]).optional(),
});

export type VerifyEmailInput = z.infer<typeof verifyEmailSchema>;

/**
 * 验证辅助函数
 */
export function validateInput<T>(schema: z.ZodSchema<T>, data: unknown): T {
  try {
    return schema.parse(data);
  } catch (error) {
    if (error instanceof z.ZodError) {
      const messages = error.errors.map((e) => `${e.path.join(".")}: ${e.message}`).join(", ");
      throw new Error(`Validation failed: ${messages}`);
    }
    throw error;
  }
}
