/**
 * Validation Utilities
 * 验证工具函数
 */

import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";
import { devMode } from '../config/dev-mode.ts';

/**
 * 验证邮箱格式
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email.trim().toLowerCase());
}

/**
 * 验证 URL 格式
 */
export function isValidUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    return parsed.protocol === "http:" || parsed.protocol === "https:";
  } catch {
    return false;
  }
}

/**
 * 验证 HTTPS URL
 */
export function isValidHttpsUrl(url: string): boolean {
  try {
    const parsed = new URL(url);
    return parsed.protocol === "https:";
  } catch {
    return false;
  }
}

/**
 * 验证 UUID 格式
 */
export function isValidUuid(id: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(id);
}

/**
 * 验证 Slug 格式
 */
export function isValidSlug(slug: string): boolean {
  const slugRegex = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
  return slugRegex.test(slug);
}

/**
 * 验证用户名格式
 */
export function isValidUsername(username: string): boolean {
  const usernameRegex = /^[a-zA-Z0-9_-]{3,30}$/;
  return usernameRegex.test(username);
}

/**
 * 检查是否包含 XSS 攻击特征
 */
export function containsXss(input: string): boolean {
  // 开发模式下可以禁用 XSS 防护
  if (!devMode.enableXssProtection) {
    return false;
  }

  const xssPatterns = [
    /<script[^>]*>.*?<\/script>/gi,
    /javascript:/gi,
    /on\w+\s*=/gi,
    /<iframe[^>]*>/gi,
    /<object[^>]*>/gi,
    /<embed[^>]*>/gi,
    /eval\s*\(/gi,
    /expression\s*\(/gi,
  ];

  return xssPatterns.some((pattern) => pattern.test(input));
}

/**
 * 检查是否包含 SQL 注入特征
 */
export function containsSqlInjection(input: string): boolean {
  // 开发模式下可以禁用 SQL 注入防护
  if (!devMode.enableSqlInjectionProtection) {
    return false;
  }

  const sqlPatterns = [
    /(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|EXECUTE)\b)/gi,
    /(--|\#|\/\*|\*\/)/g,
    /(\bOR\b|\bAND\b)\s+\d+\s*=\s*\d+/gi,
    /'\s*(OR|AND)\s*'?\d+/gi,
    /UNION\s+SELECT/gi,
  ];

  return sqlPatterns.some((pattern) => pattern.test(input));
}

/**
 * 验证域名白名单
 */
const WHITELISTED_DOMAINS = [
  "dacong.com",
  "cdn.dacong.com",
  "images.dacong.com",
  "avatars.githubusercontent.com",
  "gravatar.com",
];

export function isWhitelistedDomain(url: string): boolean {
  try {
    const parsed = new URL(url);
    return WHITELISTED_DOMAINS.some((domain) =>
      parsed.hostname === domain || parsed.hostname.endsWith(`.${domain}`)
    );
  } catch {
    return false;
  }
}

/**
 * 密码强度验证
 */
export interface PasswordStrength {
  valid: boolean;
  score: number; // 0-4
  feedback: string[];
}

export function validatePasswordStrength(password: string): PasswordStrength {
  const feedback: string[] = [];
  let score = 0;

  // 长度检查
  if (password.length < 8) {
    feedback.push("Password must be at least 8 characters");
    return { valid: false, score: 0, feedback };
  }

  if (password.length >= 8) score++;
  if (password.length >= 12) score++;

  // 复杂度检查
  const hasLowercase = /[a-z]/.test(password);
  const hasUppercase = /[A-Z]/.test(password);
  const hasNumber = /\d/.test(password);
  const hasSpecial = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password);

  if (hasLowercase && hasUppercase) score++;
  if (hasNumber) score++;
  if (hasSpecial) score++;

  // 反馈
  if (!hasLowercase) feedback.push("Add lowercase letters");
  if (!hasUppercase) feedback.push("Add uppercase letters");
  if (!hasNumber) feedback.push("Add numbers");
  if (!hasSpecial) feedback.push("Add special characters");

  // 常见密码检查
  const commonPasswords = ["password", "123456", "qwerty", "admin", "letmein"];
  if (commonPasswords.some((common) => password.toLowerCase().includes(common))) {
    feedback.push("Avoid common passwords");
    score = Math.max(0, score - 2);
  }

  const valid = score >= 3 && hasLowercase && hasUppercase && hasNumber;

  return { valid, score, feedback };
}

/**
 * 清理 HTML 标签（仅保留文本）
 */
export function stripTags(input: string): string {
  return input.replace(/<[^>]*>/g, "");
}

/**
 * 验证文件类型
 */
const ALLOWED_IMAGE_TYPES = ["image/jpeg", "image/png", "image/gif", "image/webp"];
const ALLOWED_DOCUMENT_TYPES = ["application/pdf", "text/plain"];

export function isAllowedImageType(mimeType: string): boolean {
  return ALLOWED_IMAGE_TYPES.includes(mimeType.toLowerCase());
}

export function isAllowedDocumentType(mimeType: string): boolean {
  return ALLOWED_DOCUMENT_TYPES.includes(mimeType.toLowerCase());
}

/**
 * 验证文件大小
 */
export function isValidFileSize(sizeInBytes: number, maxSizeInMB: number): boolean {
  const maxSizeInBytes = maxSizeInMB * 1024 * 1024;
  return sizeInBytes > 0 && sizeInBytes <= maxSizeInBytes;
}

/**
 * 验证 IP 地址格式
 */
export function isValidIpAddress(ip: string): boolean {
  const ipv4Regex = /^(\d{1,3}\.){3}\d{1,3}$/;
  const ipv6Regex = /^([0-9a-f]{1,4}:){7}[0-9a-f]{1,4}$/i;

  if (ipv4Regex.test(ip)) {
    const parts = ip.split(".");
    return parts.every((part) => {
      const num = parseInt(part, 10);
      return num >= 0 && num <= 255;
    });
  }

  return ipv6Regex.test(ip);
}

/**
 * 验证手机号格式（中国）
 */
export function isValidPhoneNumber(phone: string): boolean {
  const phoneRegex = /^1[3-9]\d{9}$/;
  return phoneRegex.test(phone);
}

/**
 * 验证日期格式
 */
export function isValidDate(dateString: string): boolean {
  const date = new Date(dateString);
  return date instanceof Date && !isNaN(date.getTime());
}

/**
 * 验证日期范围
 */
export function isValidDateRange(startDate: string, endDate: string): boolean {
  if (!isValidDate(startDate) || !isValidDate(endDate)) {
    return false;
  }
  return new Date(startDate) <= new Date(endDate);
}

/**
 * 验证 JSON 字符串
 */
export function isValidJson(jsonString: string): boolean {
  try {
    JSON.parse(jsonString);
    return true;
  } catch {
    return false;
  }
}

/**
 * 验证颜色代码（十六进制）
 */
export function isValidHexColor(color: string): boolean {
  const hexColorRegex = /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/;
  return hexColorRegex.test(color);
}

/**
 * 验证整数范围
 */
export function isInRange(value: number, min: number, max: number): boolean {
  return Number.isInteger(value) && value >= min && value <= max;
}

/**
 * 批量验证
 */
export interface ValidationRule {
  field: string;
  validator: (value: unknown) => boolean;
  message: string;
}

export interface ValidationError {
  field: string;
  message: string;
}

export function validateBatch(
  data: Record<string, unknown>,
  rules: ValidationRule[]
): ValidationError[] {
  const errors: ValidationError[] = [];

  for (const rule of rules) {
    const value = data[rule.field];
    if (!rule.validator(value)) {
      errors.push({
        field: rule.field,
        message: rule.message,
      });
    }
  }

  return errors;
}

/**
 * Zod 验证辅助函数（带详细错误信息）
 */
export function validateWithZod<T>(
  schema: z.ZodSchema<T>,
  data: unknown
): { success: true; data: T } | { success: false; errors: ValidationError[] } {
  // 开发模式下可以禁用输入验证
  if (!devMode.enableInputValidation) {
    return { success: true, data: data as T };
  }

  try {
    const validated = schema.parse(data);
    return { success: true, data: validated };
  } catch (error) {
    if (error instanceof z.ZodError) {
      const errors: ValidationError[] = error.errors.map((e) => ({
        field: e.path.join("."),
        message: e.message,
      }));
      return { success: false, errors };
    }
    throw error;
  }
}
