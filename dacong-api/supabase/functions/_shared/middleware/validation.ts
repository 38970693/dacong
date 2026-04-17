/**
 * Input Validation Middleware
 * 输入验证中间件
 */

import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

/**
 * 验证错误响应
 */
interface ValidationErrorResponse {
  success: false;
  error: string;
  details?: Array<{
    path: string[];
    message: string;
  }>;
}

/**
 * 验证 JSON 请求体
 * @param schema Zod Schema
 * @returns 验证后的数据或错误响应
 */
export async function validateBody<T>(
  req: Request,
  schema: z.ZodSchema<T>
): Promise<{ success: true; data: T } | { success: false; response: Response }> {
  try {
    const body = await req.json();
    const validated = schema.parse(body);
    return { success: true, data: validated };
  } catch (error) {
    if (error instanceof z.ZodError) {
      const details = error.errors.map((err) => ({
        path: err.path.map(String),
        message: err.message,
      }));

      const response = new Response(
        JSON.stringify({
          success: false,
          error: "Validation failed",
          details,
        } as ValidationErrorResponse),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );

      return { success: false, response };
    }

    // JSON 解析错误
    const response = new Response(
      JSON.stringify({
        success: false,
        error: "Invalid JSON format",
      }),
      {
        status: 400,
        headers: { "Content-Type": "application/json" },
      }
    );

    return { success: false, response };
  }
}

/**
 * 验证查询参数
 * @param req Request 对象
 * @param schema Zod Schema
 * @returns 验证后的数据或错误响应
 */
export function validateQuery<T>(
  req: Request,
  schema: z.ZodSchema<T>
): { success: true; data: T } | { success: false; response: Response } {
  try {
    const url = new URL(req.url);
    const params: Record<string, string | number> = {};

    // 提取所有查询参数
    url.searchParams.forEach((value, key) => {
      // 尝试转换数字类型
      if (/^\d+$/.test(value)) {
        params[key] = parseInt(value, 10);
      } else {
        params[key] = value;
      }
    });

    const validated = schema.parse(params);
    return { success: true, data: validated };
  } catch (error) {
    if (error instanceof z.ZodError) {
      const details = error.errors.map((err) => ({
        path: err.path.map(String),
        message: err.message,
      }));

      const response = new Response(
        JSON.stringify({
          success: false,
          error: "Validation failed",
          details,
        } as ValidationErrorResponse),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );

      return { success: false, response };
    }

    const response = new Response(
      JSON.stringify({
        success: false,
        error: "Invalid query parameters",
      }),
      {
        status: 400,
        headers: { "Content-Type": "application/json" },
      }
    );

    return { success: false, response };
  }
}

/**
 * 验证路径参数
 * @param params 路径参数对象
 * @param schema Zod Schema
 * @returns 验证后的数据或错误响应
 */
export function validateParams<T>(
  params: Record<string, string>,
  schema: z.ZodSchema<T>
): { success: true; data: T } | { success: false; response: Response } {
  try {
    const validated = schema.parse(params);
    return { success: true, data: validated };
  } catch (error) {
    if (error instanceof z.ZodError) {
      const details = error.errors.map((err) => ({
        path: err.path.map(String),
        message: err.message,
      }));

      const response = new Response(
        JSON.stringify({
          success: false,
          error: "Validation failed",
          details,
        } as ValidationErrorResponse),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );

      return { success: false, response };
    }

    const response = new Response(
      JSON.stringify({
        success: false,
        error: "Invalid path parameters",
      }),
      {
        status: 400,
        headers: { "Content-Type": "application/json" },
      }
    );

    return { success: false, response };
  }
}
