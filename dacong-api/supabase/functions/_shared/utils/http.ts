/**
 * HTTP Utilities
 * HTTP工具函数 - 处理请求和响应
 */

import { ApiResponse } from "../dto/ApiResponse.ts";

/**
 * 创建JSON响应
 */
export function jsonResponse<T>(
  data: ApiResponse<T>,
  status = 200
): Response {
  return new Response(JSON.stringify(data.toJSON()), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    },
  });
}

/**
 * 创建成功响应
 */
export function successResponse<T>(
  data: T,
  meta?: Record<string, unknown>
): Response {
  return jsonResponse(ApiResponse.ok(data, meta), 200);
}

/**
 * 创建错误响应
 */
export function errorResponse(error: string, status = 400): Response {
  return jsonResponse(ApiResponse.fail(error), status);
}

/**
 * 处理CORS预检请求
 */
export function corsResponse(): Response {
  return new Response(null, {
    status: 204,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    },
  });
}

/**
 * 从请求中获取JSON数据
 */
export async function getRequestBody<T>(req: Request): Promise<T> {
  try {
    return await req.json();
  } catch {
    throw new Error("Invalid JSON body");
  }
}

/**
 * 从请求中获取查询参数
 */
export function getQueryParams(req: Request): URLSearchParams {
  const url = new URL(req.url);
  return url.searchParams;
}

/**
 * 获取客户端IP地址
 */
export function getClientIp(req: Request): string | null {
  return (
    req.headers.get("x-forwarded-for")?.split(",")[0].trim() ||
    req.headers.get("x-real-ip") ||
    null
  );
}

/**
 * 获取User-Agent
 */
export function getUserAgent(req: Request): string | null {
  return req.headers.get("user-agent");
}

/**
 * 验证请求方法
 */
export function validateMethod(req: Request, allowedMethods: string[]): void {
  if (!allowedMethods.includes(req.method)) {
    throw new Error(`Method ${req.method} not allowed`);
  }
}
