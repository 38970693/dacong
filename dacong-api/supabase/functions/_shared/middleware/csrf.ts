/**
 * CSRF 防护中间件
 *
 * 实现原理：
 * 1. Double Submit Cookie 模式
 * 2. Token 存储在 HttpOnly Cookie 中
 * 3. 请求时需要在 Header 中携带相同的 Token
 * 4. 服务端验证 Cookie 和 Header 中的 Token 是否一致
 *
 * 安全特性：
 * - 加密安全的随机数生成
 * - Token 有效期 1 小时
 * - HttpOnly, Secure, SameSite=Strict
 * - 时间戳验证防止重放攻击
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const CSRF_TOKEN_LENGTH = 32;
const CSRF_TOKEN_EXPIRY = 3600; // 1 小时（秒）
const CSRF_COOKIE_NAME = 'csrf_token';
const CSRF_HEADER_NAME = 'x-csrf-token';

interface CsrfToken {
  token: string;
  timestamp: number;
}

/**
 * 生成加密安全的随机 Token
 */
function generateSecureToken(): string {
  const array = new Uint8Array(CSRF_TOKEN_LENGTH);
  crypto.getRandomValues(array);
  return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
}

/**
 * 生成 CSRF Token（包含时间戳）
 */
export function generateCsrfToken(): CsrfToken {
  const token = generateSecureToken();
  const timestamp = Date.now();

  return {
    token,
    timestamp,
  };
}

/**
 * 编码 Token（token:timestamp）
 */
function encodeToken(csrfToken: CsrfToken): string {
  return `${csrfToken.token}:${csrfToken.timestamp}`;
}

/**
 * 解码 Token
 */
function decodeToken(encoded: string): CsrfToken | null {
  const parts = encoded.split(':');
  if (parts.length !== 2) {
    return null;
  }

  const [token, timestampStr] = parts;
  const timestamp = parseInt(timestampStr, 10);

  if (isNaN(timestamp) || token.length !== CSRF_TOKEN_LENGTH * 2) {
    return null;
  }

  return { token, timestamp };
}

/**
 * 验证 Token 是否过期
 */
function isTokenExpired(timestamp: number): boolean {
  const now = Date.now();
  const age = (now - timestamp) / 1000; // 转换为秒
  return age > CSRF_TOKEN_EXPIRY;
}

/**
 * 从 Cookie 中提取 CSRF Token
 */
function extractCsrfTokenFromCookie(req: Request): CsrfToken | null {
  const cookieHeader = req.headers.get('Cookie');
  if (!cookieHeader) {
    return null;
  }

  const cookies = cookieHeader.split(';').map(c => c.trim());
  const csrfCookie = cookies.find(c => c.startsWith(`${CSRF_COOKIE_NAME}=`));

  if (!csrfCookie) {
    return null;
  }

  const encoded = csrfCookie.substring(CSRF_COOKIE_NAME.length + 1);
  return decodeToken(encoded);
}

/**
 * 从 Header 中提取 CSRF Token
 */
function extractCsrfTokenFromHeader(req: Request): string | null {
  return req.headers.get(CSRF_HEADER_NAME);
}

/**
 * 验证 CSRF Token
 *
 * @param req - HTTP 请求对象
 * @returns 验证成功返回 null，失败返回错误响应
 */
export async function validateCsrfToken(req: Request): Promise<Response | null> {
  // 从 Cookie 中提取 Token
  const cookieToken = extractCsrfTokenFromCookie(req);
  if (!cookieToken) {
    return new Response(
      JSON.stringify({ error: 'CSRF token missing in cookie' }),
      {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }

  // 检查 Token 是否过期
  if (isTokenExpired(cookieToken.timestamp)) {
    return new Response(
      JSON.stringify({ error: 'CSRF token expired' }),
      {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }

  // 从 Header 中提取 Token
  const headerToken = extractCsrfTokenFromHeader(req);
  if (!headerToken) {
    return new Response(
      JSON.stringify({ error: 'CSRF token missing in header' }),
      {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }

  // 验证 Cookie 和 Header 中的 Token 是否一致
  const encodedCookieToken = encodeToken(cookieToken);
  if (headerToken !== encodedCookieToken) {
    return new Response(
      JSON.stringify({ error: 'CSRF token mismatch' }),
      {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }

  // 验证通过
  return null;
}

/**
 * CSRF 中间件
 *
 * 使用方式：
 * ```typescript
 * serve(async (req) => {
 *   const csrfError = await csrfMiddleware(req);
 *   if (csrfError) return csrfError;
 *
 *   // 业务逻辑
 * })
 * ```
 */
export async function csrfMiddleware(req: Request): Promise<Response | null> {
  // 只对状态变更方法进行 CSRF 验证
  const method = req.method.toUpperCase();
  if (!['POST', 'PUT', 'PATCH', 'DELETE'].includes(method)) {
    return null;
  }

  return await validateCsrfToken(req);
}

/**
 * 生成 Set-Cookie Header
 */
export function generateCsrfCookieHeader(csrfToken: CsrfToken): string {
  const encoded = encodeToken(csrfToken);
  const isProduction = Deno.env.get('ENVIRONMENT') === 'production';

  const cookieAttributes = [
    `${CSRF_COOKIE_NAME}=${encoded}`,
    'HttpOnly',
    'SameSite=Strict',
    `Max-Age=${CSRF_TOKEN_EXPIRY}`,
    'Path=/',
  ];

  // 生产环境启用 Secure
  if (isProduction) {
    cookieAttributes.push('Secure');
  }

  return cookieAttributes.join('; ');
}

/**
 * 创建带 CSRF Token 的响应
 */
export function createResponseWithCsrfToken(
  body: string | null,
  init?: ResponseInit
): Response {
  const csrfToken = generateCsrfToken();
  const cookieHeader = generateCsrfCookieHeader(csrfToken);

  const headers = new Headers(init?.headers || {});
  headers.set('Set-Cookie', cookieHeader);
  headers.set('Content-Type', 'application/json');

  return new Response(body, {
    ...init,
    headers,
  });
}
