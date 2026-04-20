/**
 * XSS Protection and Input Sanitization Utilities
 * XSS 防护和输入清理工具
 */

/**
 * HTML 实体转义映射
 */
const HTML_ENTITIES: Record<string, string> = {
  "&": "&amp;",
  "<": "&lt;",
  ">": "&gt;",
  '"': "&quot;",
  "'": "&#039;",
  "/": "&#x2F;",
};

/**
 * HTML 转义 - 防止 XSS 攻击
 * @param text 需要转义的文本
 * @returns 转义后的安全文本
 */
export function escapeHtml(text: string): string {
  return text.replace(/[&<>"'/]/g, (char) => HTML_ENTITIES[char] || char);
}

/**
 * 清理用户输入 - 移除危险字符和多余空白
 * @param input 用户输入
 * @returns 清理后的安全文本
 */
export function sanitizeUserInput(input: string): string {
  // 1. 移除前后空白
  let sanitized = input.trim();

  // 2. 移除 HTML 标签
  sanitized = sanitized.replace(/<[^>]*>/g, "");

  // 3. 移除 JavaScript 协议
  sanitized = sanitized.replace(/javascript:/gi, "");

  // 4. 移除 data: 协议
  sanitized = sanitized.replace(/data:/gi, "");

  // 5. 移除 vbscript: 协议
  sanitized = sanitized.replace(/vbscript:/gi, "");

  // 6. 移除 on* 事件处理器
  sanitized = sanitized.replace(/on\w+\s*=/gi, "");

  // 7. 规范化空白字符
  sanitized = sanitized.replace(/\s+/g, " ");

  // 8. HTML 转义
  sanitized = escapeHtml(sanitized);

  return sanitized;
}

/**
 * 清理 URL - 仅允许安全协议
 * @param url URL 字符串
 * @returns 清理后的安全 URL 或空字符串
 */
export function sanitizeUrl(url: string): string {
  const trimmed = url.trim();

  // 允许的协议白名单
  const allowedProtocols = ["http:", "https:", "mailto:", "tel:"];

  try {
    const parsed = new URL(trimmed);

    if (allowedProtocols.includes(parsed.protocol)) {
      return trimmed;
    }

    return "";
  } catch {
    // 如果不是有效的 URL，返回空字符串
    return "";
  }
}

/**
 * 敏感词列表
 */
const SENSITIVE_WORDS = [
  // 中文敏感词
  "垃圾", "傻逼", "操你", "妈的", "草泥马",
  // 英文敏感词
  "fuck", "shit", "damn", "bitch", "asshole",
  // 可以根据需要扩展
];

/**
 * 检查文本是否包含敏感词
 * @param text 待检查的文本
 * @returns 是否包含敏感词
 */
export function containsSensitiveWords(text: string): boolean {
  const lowerText = text.toLowerCase();
  return SENSITIVE_WORDS.some((word) => lowerText.includes(word.toLowerCase()));
}

/**
 * 过滤敏感词 - 用 * 替换
 * @param text 待过滤的文本
 * @returns 过滤后的文本
 */
export function filterSensitiveWords(text: string): string {
  let filtered = text;

  SENSITIVE_WORDS.forEach((word) => {
    const regex = new RegExp(word, "gi");
    filtered = filtered.replace(regex, "*".repeat(word.length));
  });

  return filtered;
}

/**
 * 清理评论内容
 * @param content 评论内容
 * @returns 清理后的内容和审核状态
 */
export function sanitizeComment(content: string): {
  sanitized: string;
  needsModeration: boolean;
} {
  // 清理输入
  const sanitized = sanitizeUserInput(content);

  // 检查是否需要审核
  const needsModeration = containsSensitiveWords(sanitized);

  return {
    sanitized,
    needsModeration,
  };
}

/**
 * 验证并清理邮箱地址
 * @param email 邮箱地址
 * @returns 清理后的邮箱或 null
 */
export function sanitizeEmail(email: string): string | null {
  const trimmed = email.trim().toLowerCase();

  // 简单的邮箱格式验证
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (emailRegex.test(trimmed)) {
    return trimmed;
  }

  return null;
}

/**
 * 清理文件名 - 防止路径遍历攻击
 * @param filename 文件名
 * @returns 安全的文件名
 */
export function sanitizeFilename(filename: string): string {
  // 移除路径分隔符
  let sanitized = filename.replace(/[/\\]/g, "");

  // 移除特殊字符
  sanitized = sanitized.replace(/[^a-zA-Z0-9._-]/g, "_");

  // 限制长度
  if (sanitized.length > 255) {
    sanitized = sanitized.substring(0, 255);
  }

  return sanitized;
}

/**
 * SQL 注入防护 - 验证标识符
 * 注意：这不是替代参数化查询的方案，仅用于验证表名、列名等标识符
 * @param identifier 标识符（表名、列名等）
 * @returns 是否为安全的标识符
 */
export function isValidSqlIdentifier(identifier: string): boolean {
  // 仅允许字母、数字、下划线
  const identifierRegex = /^[a-zA-Z_][a-zA-Z0-9_]*$/;
  return identifierRegex.test(identifier);
}

/**
 * 清理 JSON 字符串 - 防止 JSON 注入
 * @param jsonString JSON 字符串
 * @returns 解析并重新序列化的安全 JSON
 */
export function sanitizeJson(jsonString: string): string | null {
  try {
    const parsed = JSON.parse(jsonString);
    return JSON.stringify(parsed);
  } catch {
    return null;
  }
}

/**
 * 清理 Markdown - 允许安全的 Markdown 语法
 * @param markdown Markdown 文本
 * @returns 清理后的 Markdown
 */
export function sanitizeMarkdown(markdown: string): string {
  // 移除 HTML 标签（Markdown 中的 HTML）
  let sanitized = markdown.replace(/<script[^>]*>.*?<\/script>/gi, "");
  sanitized = sanitized.replace(/<iframe[^>]*>.*?<\/iframe>/gi, "");
  sanitized = sanitized.replace(/<object[^>]*>.*?<\/object>/gi, "");
  sanitized = sanitized.replace(/<embed[^>]*>/gi, "");

  // 移除危险的事件处理器
  sanitized = sanitized.replace(/on\w+\s*=/gi, "");

  // 移除 javascript: 协议
  sanitized = sanitized.replace(/javascript:/gi, "");

  return sanitized.trim();
}

/**
 * 检查字符串长度（考虑多字节字符）
 * @param text 文本
 * @param maxLength 最大长度
 * @returns 是否超过长度限制
 */
export function exceedsLength(text: string, maxLength: number): boolean {
  // 使用 Array.from 正确处理多字节字符（如 emoji）
  return Array.from(text).length > maxLength;
}

/**
 * 截断文本（考虑多字节字符）
 * @param text 文本
 * @param maxLength 最大长度
 * @param suffix 后缀（如 "..."）
 * @returns 截断后的文本
 */
export function truncateText(text: string, maxLength: number, suffix = "..."): string {
  const chars = Array.from(text);
  if (chars.length <= maxLength) {
    return text;
  }
  return chars.slice(0, maxLength - suffix.length).join("") + suffix;
}

/**
 * 清理 SQL 标识符（表名、列名等）
 * 注意：这不能替代参数化查询，仅用于动态标识符验证
 * @param identifier 标识符
 * @returns 清理后的标识符或 null
 */
export function sanitizeSqlIdentifier(identifier: string): string | null {
  // 仅允许字母、数字、下划线
  if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(identifier)) {
    return null;
  }

  // 检查 SQL 关键字
  const sqlKeywords = [
    "SELECT", "INSERT", "UPDATE", "DELETE", "DROP", "CREATE", "ALTER",
    "TABLE", "DATABASE", "INDEX", "VIEW", "PROCEDURE", "FUNCTION",
    "TRIGGER", "GRANT", "REVOKE", "UNION", "WHERE", "FROM", "JOIN",
  ];

  if (sqlKeywords.includes(identifier.toUpperCase())) {
    return null;
  }

  return identifier;
}

/**
 * 清理搜索查询 - 移除特殊字符
 * @param query 搜索查询
 * @returns 清理后的查询
 */
export function sanitizeSearchQuery(query: string): string {
  // 移除特殊字符，保留字母、数字、空格、中文字符
  let sanitized = query.replace(/[^\w\s\u4e00-\u9fa5]/g, " ");

  // 规范化空白
  sanitized = sanitized.replace(/\s+/g, " ").trim();

  return sanitized;
}

/**
 * 验证并清理颜色代码
 * @param color 颜色代码
 * @returns 清理后的颜色代码或 null
 */
export function sanitizeColor(color: string): string | null {
  const hexColorRegex = /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/;

  if (hexColorRegex.test(color)) {
    return color.toLowerCase();
  }

  return null;
}

/**
 * 清理标签名称
 * @param tag 标签名称
 * @returns 清理后的标签
 */
export function sanitizeTag(tag: string): string {
  // 转小写
  let sanitized = tag.toLowerCase().trim();

  // 移除特殊字符，保留字母、数字、连字符、下划线
  sanitized = sanitized.replace(/[^a-z0-9\-_]/g, "");

  // 移除多余的连字符
  sanitized = sanitized.replace(/-+/g, "-");

  // 移除首尾连字符
  sanitized = sanitized.replace(/^-+|-+$/g, "");

  return sanitized;
}

/**
 * 清理 Slug
 * @param text 文本
 * @returns Slug
 */
export function sanitizeSlug(text: string): string {
  let slug = text.toLowerCase().trim();

  // 替换空格为连字符
  slug = slug.replace(/\s+/g, "-");

  // 移除特殊字符
  slug = slug.replace(/[^a-z0-9\-]/g, "");

  // 移除多余的连字符
  slug = slug.replace(/-+/g, "-");

  // 移除首尾连字符
  slug = slug.replace(/^-+|-+$/g, "");

  return slug;
}

/**
 * 深度清理对象（递归清理所有字符串字段）
 * @param obj 对象
 * @returns 清理后的对象
 */
export function deepSanitize<T>(obj: T): T {
  if (typeof obj === "string") {
    return sanitizeUserInput(obj) as T;
  }

  if (Array.isArray(obj)) {
    return obj.map((item) => deepSanitize(item)) as T;
  }

  if (obj !== null && typeof obj === "object") {
    const sanitized: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(obj)) {
      sanitized[key] = deepSanitize(value);
    }
    return sanitized as T;
  }

  return obj;
}
