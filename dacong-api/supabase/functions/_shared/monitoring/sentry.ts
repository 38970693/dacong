/**
 * Sentry 错误监控配置
 * 用于 Supabase Edge Functions 的错误追踪和性能监控
 */

import * as Sentry from "https://deno.land/x/sentry@7.119.0/index.mjs";

interface SentryConfig {
  dsn?: string;
  environment?: string;
  release?: string;
  tracesSampleRate?: number;
  debug?: boolean;
}

let isInitialized = false;

/**
 * 初始化 Sentry
 */
export function initSentry(config: SentryConfig = {}): void {
  const dsn = config.dsn || Deno.env.get("SENTRY_DSN");

  if (!dsn) {
    console.warn("Sentry DSN not configured, skipping initialization");
    return;
  }

  if (isInitialized) {
    return;
  }

  Sentry.init({
    dsn,
    environment: config.environment || Deno.env.get("ENVIRONMENT") || "production",
    release: config.release || "dacong-api@1.0.0",
    tracesSampleRate: config.tracesSampleRate ?? 0.2,
    debug: config.debug ?? false,

    // 过滤敏感信息
    beforeSend(event) {
      // 移除敏感的请求数据
      if (event.request?.data) {
        const data = event.request.data as Record<string, unknown>;
        delete data.password;
        delete data.token;
        delete data.api_key;
        delete data.apiKey;
      }

      // 移除敏感的环境变量
      if (event.contexts?.runtime?.env) {
        const env = event.contexts.runtime.env as Record<string, unknown>;
        const sensitiveKeys = [
          "SUPABASE_SERVICE_ROLE_KEY",
          "ANTHROPIC_API_KEY",
          "OPENROUTER_API_KEY",
          "GITHUB_TOKEN",
        ];
        sensitiveKeys.forEach((key) => {
          if (key in env) {
            env[key] = "***REDACTED***";
          }
        });
      }

      return event;
    },

    // 面包屑过滤
    beforeBreadcrumb(breadcrumb) {
      // 过滤掉不重要的面包屑
      if (breadcrumb.category === "console" && breadcrumb.level === "debug") {
        return null;
      }
      return breadcrumb;
    },
  });

  isInitialized = true;
  console.log("Sentry initialized successfully");
}

/**
 * 设置用户上下文
 */
export function setUser(userId: string, extras?: Record<string, unknown>): void {
  Sentry.setUser({
    id: userId,
    ...extras,
  });
}

/**
 * 清除用户上下文
 */
export function clearUser(): void {
  Sentry.setUser(null);
}

/**
 * 设置标签
 */
export function setTag(key: string, value: string): void {
  Sentry.setTag(key, value);
}

/**
 * 设置上下文
 */
export function setContext(key: string, context: Record<string, unknown>): void {
  Sentry.setContext(key, context);
}

/**
 * 添加面包屑
 */
export function addBreadcrumb(
  message: string,
  options?: {
    category?: string;
    level?: Sentry.SeverityLevel;
    data?: Record<string, unknown>;
  }
): void {
  Sentry.addBreadcrumb({
    message,
    category: options?.category,
    level: options?.level || "info",
    data: options?.data,
  });
}

/**
 * 捕获异常
 */
export function captureException(
  exception: unknown,
  options?: {
    level?: Sentry.SeverityLevel;
    extras?: Record<string, unknown>;
    tags?: Record<string, string>;
  }
): string {
  return Sentry.captureException(exception, {
    level: options?.level || "error",
    extra: options?.extras,
    tags: options?.tags,
  });
}

/**
 * 捕获消息
 */
export function captureMessage(
  message: string,
  options?: {
    level?: Sentry.SeverityLevel;
    extras?: Record<string, unknown>;
    tags?: Record<string, string>;
  }
): string {
  return Sentry.captureMessage(message, {
    level: options?.level || "info",
    extra: options?.extras,
    tags: options?.tags,
  });
}

/**
 * 开始性能追踪事务
 */
export function startTransaction(
  name: string,
  op: string,
  description?: string
): Sentry.Transaction {
  return Sentry.startTransaction({
    name,
    op,
    description,
  });
}

/**
 * Edge Function 错误处理中间件
 */
export function withSentry<T>(
  handler: (req: Request) => Promise<Response>,
  options?: {
    functionName?: string;
    tags?: Record<string, string>;
  }
): (req: Request) => Promise<Response> {
  return async (req: Request): Promise<Response> => {
    // 初始化 Sentry（如果尚未初始化）
    if (!isInitialized) {
      initSentry();
    }

    // 设置函数标签
    if (options?.functionName) {
      setTag("function_name", options.functionName);
    }
    if (options?.tags) {
      Object.entries(options.tags).forEach(([key, value]) => {
        setTag(key, value);
      });
    }

    // 开始性能追踪
    const transaction = startTransaction(
      options?.functionName || "edge-function",
      "http.server",
      `${req.method} ${new URL(req.url).pathname}`
    );

    try {
      // 添加请求面包屑
      addBreadcrumb("Request received", {
        category: "http",
        level: "info",
        data: {
          method: req.method,
          url: req.url,
          headers: Object.fromEntries(req.headers.entries()),
        },
      });

      // 执行处理器
      const response = await handler(req);

      // 记录响应状态
      transaction.setHttpStatus(response.status);

      if (response.status >= 400) {
        addBreadcrumb("Error response", {
          category: "http",
          level: "warning",
          data: {
            status: response.status,
            statusText: response.statusText,
          },
        });
      }

      return response;
    } catch (error) {
      // 捕获异常
      captureException(error, {
        level: "error",
        extras: {
          method: req.method,
          url: req.url,
          function_name: options?.functionName,
        },
      });

      transaction.setHttpStatus(500);

      // 返回错误响应
      return new Response(
        JSON.stringify({
          error: "Internal Server Error",
          message: error instanceof Error ? error.message : "Unknown error",
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        }
      );
    } finally {
      // 完成事务
      transaction.finish();
    }
  };
}

/**
 * 报告 API 错误
 */
export function reportApiError(
  error: unknown,
  context: {
    endpoint?: string;
    method?: string;
    statusCode?: number;
    userId?: string;
    extras?: Record<string, unknown>;
  }
): void {
  addBreadcrumb("API error", {
    category: "api",
    level: "error",
    data: {
      endpoint: context.endpoint,
      method: context.method,
      status_code: context.statusCode,
      user_id: context.userId,
    },
  });

  captureException(error, {
    level: "error",
    extras: {
      endpoint: context.endpoint,
      method: context.method,
      status_code: context.statusCode,
      user_id: context.userId,
      ...context.extras,
    },
  });
}

/**
 * 报告性能问题
 */
export function reportPerformanceIssue(
  operation: string,
  durationMs: number,
  thresholdMs = 3000,
  extras?: Record<string, unknown>
): void {
  if (durationMs > thresholdMs) {
    captureMessage(
      `Slow operation: ${operation} took ${durationMs.toFixed(2)}ms`,
      {
        level: "warning",
        extras: {
          operation,
          duration_ms: durationMs,
          threshold_ms: thresholdMs,
          ...extras,
        },
      }
    );
  }
}

/**
 * 报告数据库错误
 */
export function reportDatabaseError(
  error: unknown,
  context: {
    operation?: string;
    table?: string;
    query?: string;
    extras?: Record<string, unknown>;
  }
): void {
  addBreadcrumb("Database error", {
    category: "database",
    level: "error",
    data: {
      operation: context.operation,
      table: context.table,
    },
  });

  captureException(error, {
    level: "error",
    extras: {
      operation: context.operation,
      table: context.table,
      query: context.query,
      ...context.extras,
    },
    tags: {
      error_type: "database",
    },
  });
}
