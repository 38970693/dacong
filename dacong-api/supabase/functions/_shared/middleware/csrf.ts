/**
 * CSRF 防护中间件
 *
 * 实现原理：
 * 1. Double Submit Cookie 模式 + 数据库存储
 * 2. Token 存储在 HttpOnly Cookie 和数据库中
 * 3. 请求时需要在 Header 中携带相同的 Token
 * 4. 服务端验证 Cookie、Header 和数据库中的 Token 是否一致
 *
 * 安全特性：
 * - 加密安全的随机数生成
 * - Token 有效期 1 小时
 * - HttpOnly, Secure, SameSite=Strict
 * - 时间戳验证防止重放攻击
 * - 数据库持久化存储
 * - 用户会话绑定
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import { devMode } from '../config/dev-mode.ts';

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
 * 验证 CSRF Token（带数据库验证）
 *
 * @param req - HTTP 请求对象
 * @param supabase - Supabase 客户端
 * @param userId - 用户 ID（可选，用于验证 Token 所有权）
 * @returns 验证成功返回 null，失败返回错误响应
 */
export async function validateCsrfToken(
  req: Request,
  supabase?: SupabaseClient,
  userId?: string
): Promise<Response | null> {
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

  // 验证 Cookie 和 Header 中的 Token 是否一致（常量时间比较）
  const encodedCookieToken = encodeToken(cookieToken);
  if (!constantTimeCompare(headerToken, encodedCookieToken)) {
    return new Response(
      JSON.stringify({ error: 'CSRF token mismatch' }),
      {
        status: 403,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }

  // 如果提供了 Supabase 客户端，验证数据库中的 Token
  if (supabase) {
    const dbValidation = await validateTokenInDatabase(
      supabase,
      cookieToken.token,
      userId
    );
    if (dbValidation) {
      return dbValidation;
    }
  }

  // 验证通过
  return null;
}

/**
 * 常量时间字符串比较（防止时序攻击）
 */
function constantTimeCompare(a: string, b: string): boolean {
  if (a.length !== b.length) {
    return false;
  }

  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }

  return result === 0;
}

/**
 * 在数据库中验证 Token
 */
async function validateTokenInDatabase(
  supabase: SupabaseClient,
  token: string,
  userId?: string
): Promise<Response | null> {
  try {
    let query = supabase
      .from('csrf_tokens')
      .select('*')
      .eq('token', token)
      .gt('expires_at', new Date().toISOString())
      .single();

    // 如果提供了 userId，验证 Token 属于该用户
    if (userId) {
      query = query.eq('user_id', userId);
    }

    const { data, error } = await query;

    if (error || !data) {
      return new Response(
        JSON.stringify({ error: 'Invalid or expired CSRF token' }),
        {
          status: 403,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }

    // 更新最后使用时间
    await supabase
      .from('csrf_tokens')
      .update({ last_used_at: new Date().toISOString() })
      .eq('id', data.id);

    return null;
  } catch (err) {
    console.error('CSRF token database validation error:', err);
    return new Response(
      JSON.stringify({ error: 'CSRF token validation failed' }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
}

/**
 * CSRF 中间件
 *
 * 使用方式：
 * ```typescript
 * serve(async (req) => {
 *   const csrfError = await csrfMiddleware(req, supabase, userId);
 *   if (csrfError) return csrfError;
 *
 *   // 业务逻辑
 * })
 * ```
 */
export async function csrfMiddleware(
  req: Request,
  supabase?: SupabaseClient,
  userId?: string
): Promise<Response | null> {
  // 开发模式下可以禁用 CSRF 验证
  if (!devMode.enableCsrf) {
    return null;
  }

  // 只对状态变更方法进行 CSRF 验证
  const method = req.method.toUpperCase();
  if (!['POST', 'PUT', 'PATCH', 'DELETE'].includes(method)) {
    return null;
  }

  return await validateCsrfToken(req, supabase, userId);
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
 * 创建带 CSRF Token 的响应（并存储到数据库）
 */
export async function createResponseWithCsrfToken(
  body: string | null,
  init?: ResponseInit,
  supabase?: SupabaseClient,
  userId?: string,
  req?: Request
): Promise<Response> {
  const csrfToken = generateCsrfToken();
  const cookieHeader = generateCsrfCookieHeader(csrfToken);

  // 如果提供了 Supabase 客户端，将 Token 存储到数据库
  if (supabase && userId) {
    await storeCsrfTokenInDatabase(supabase, csrfToken, userId, req);
  }

  const headers = new Headers(init?.headers || {});
  headers.set('Set-Cookie', cookieHeader);
  headers.set('Content-Type', 'application/json');

  // 同时在响应体中返回 Token（供客户端使用）
  let responseBody = body;
  if (body) {
    try {
      const data = JSON.parse(body);
      data.csrf_token = encodeToken(csrfToken);
      responseBody = JSON.stringify(data);
    } catch {
      // 如果解析失败，保持原样
    }
  }

  return new Response(responseBody, {
    ...init,
    headers,
  });
}

/**
 * 将 CSRF Token 存储到数据库
 */
async function storeCsrfTokenInDatabase(
  supabase: SupabaseClient,
  csrfToken: CsrfToken,
  userId: string,
  req?: Request
): Promise<void> {
  try {
    const expiresAt = new Date(csrfToken.timestamp + CSRF_TOKEN_EXPIRY * 1000);
    const ipAddress = req?.headers.get('x-forwarded-for') ||
                      req?.headers.get('x-real-ip') ||
                      'unknown';
    const userAgent = req?.headers.get('user-agent') || 'unknown';

    await supabase.from('csrf_tokens').insert({
      user_id: userId,
      token: csrfToken.token,
      expires_at: expiresAt.toISOString(),
      ip_address: ipAddress,
      user_agent: userAgent,
    });
  } catch (err) {
    console.error('Failed to store CSRF token in database:', err);
    // 不抛出错误，允许继续使用 Cookie 模式
  }
}

/**
 * 生成新的 CSRF Token（用于 Token 刷新）
 */
export async function refreshCsrfToken(
  supabase: SupabaseClient,
  userId: string,
  req?: Request
): Promise<CsrfToken> {
  const csrfToken = generateCsrfToken();
  await storeCsrfTokenInDatabase(supabase, csrfToken, userId, req);
  return csrfToken;
}

/**
 * 清除用户的所有 CSRF Token
 */
export async function clearUserCsrfTokens(
  supabase: SupabaseClient,
  userId: string
): Promise<void> {
  try {
    await supabase
      .from('csrf_tokens')
      .delete()
      .eq('user_id', userId);
  } catch (err) {
    console.error('Failed to clear CSRF tokens:', err);
  }
}
