/**
 * Get CSRF Token Edge Function
 * 获取 CSRF Token 的 API 端点
 *
 * 用途：
 * - 前端应用启动时获取初始 Token
 * - Token 过期后刷新
 * - 登录后获取新 Token
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import {
  generateCsrfToken,
  generateCsrfCookieHeader,
} from '../_shared/middleware/csrf.ts';

serve(async (req) => {
  // 处理 CORS 预检请求
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Max-Age': '86400',
      },
    });
  }

  // 只允许 GET 请求
  if (req.method !== 'GET') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }

  try {
    // 生成新的 CSRF Token
    const csrfToken = generateCsrfToken();
    const cookieHeader = generateCsrfCookieHeader(csrfToken);

    // 返回 Token（同时设置 Cookie）
    return new Response(
      JSON.stringify({
        token: `${csrfToken.token}:${csrfToken.timestamp}`,
        expiresIn: 3600, // 1 小时
      }),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Set-Cookie': cookieHeader,
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Credentials': 'true',
        },
      }
    );
  } catch (error) {
    console.error('Error generating CSRF token:', error);

    return new Response(
      JSON.stringify({ error: 'Failed to generate CSRF token' }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
});
