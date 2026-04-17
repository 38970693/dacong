/**
 * Sentry 错误监控配置
 * 用于 Supabase Edge Functions
 */

import * as Sentry from "https://deno.land/x/sentry@7.114.0/index.mjs";

interface SentryConfig {
  dsn?: string;
  environment?: string;
  release?: string;
  tracesSampleRate?: number;
  debug?: boolean;
}

/**
 * 初始化 Sentry
 */
export function initSentry(config?: SentryConfig) {
  const dsn = config?.dsn || Deno.env.get("SENTRY_DSN");

  if (!dsn) {
    console.warn("Sentry DSN not configured, skipping initialization");
    return;
  }

  Sentry.init({
    dsn,
    environment: config?.environment || Deno.env.get("ENVIRONMENT") || "production",
    release: config?.release || "dacong-api@1.0.0",
    tracesSampleRate: config?.tracesSampleRate || 0.2,
    debug: config?.debug || false,

    // 集成配置
    integrations: [
      new Sentry.Integrations.Http({ tracing: true }),
    ],

    // 过滤敏感信息
    beforeSend(event) {
      // 移除敏感请求数据
      if (event.request?.data) {
        const data = event.request.data as Record<string, unknown>;
        delete data.password;
        delete data.token;
        delete data.api_key;
        delete data.authorization;
      }

      // 移除敏感 headers
      if (event.request?.headers) {
        const headers = event.request.headers as Record<string, string>;
        delete headers.authorization;
        delete headers["x-api-key"];
      }

      return event;
    },

    // 面包屑过滤
    beforeBreadcrumb(breadcrumb) {
      // 过滤掉健康检查请求
      if (breadcrumb.category === "http" && breadcrumb.data?.url?.includes("/health")) {
        return null;
      }
      return breadcrumb;
    },
  });

  console.log("Sentry initialized successfully");
}

/**
 * 设置用户上下文
 */
export function setUser(user: {
  id: string;
  email?: string;
  username?: string;
  [key: string]: unknown;
}) {
  Sentry.setUser(user);
}

/**
 * 清除用户上下文
 */
export function clearUser() {
  Sentry.setUser(null);
}

/**
 * 设置标签
 */
export function setTag(key: string, value: string) {
  Sentry.setTag(key, value);
}

/**
 * 设置上下文
 */
export function setContext(key: string, context: Record<string, unknown>) {
  Sentry.setContext(key, context);
}

/**
 * 添加面包屑
 */
export function addBreadcrumb(breadcrumb: {
  message: string;
  category?: string;
  level?: Sentry.SeverityLevel;
  data?: Record<string, unknown>;
}) {
  Sentry.addBreadcrumb(breadcrumb);
}

/**
 * 捕获异常
 */
export function captureException(
  exception: unknown,
  hint?: string,
  level?: Sentry.SeverityLevel,
) {
  Sentry.captureException(exception, {
    level: level || "error",
    contexts: hint ? { hint: { message: hint } } : undefined,
  });
}

/**
 * 捕获消息
 */
export function captureMessage(
  message: string,
  level?: Sentry.SeverityLevel,
  extras?: Record<string, unknown>,
) {
  Sentry.captureMessage(message, {
    level: level || "info",
    extra: extras,
  });
}

/**
 * 开始事务
 */
export function startTransaction(
  name: string,
  op: string,
  description?: string,
) {
  return Sentry.startTransaction({
    name,
    op,
    description,
  });
}

/**
 * Edge Function 错误处理包装器
 */
export function withSentry<T>(
  handler: (req: Request) => Promise<Response>,
  options?: {
    functionName?: string;
    captureErrors?: boolean;
  },
) {
  return async (req: Request): Promise<Response> => {
    const transaction = startTransaction(
      options?.functionName || "edge-function",
      "http.server",
      `${req.method} ${new URL(req.url).pathname}`,
    );

    try {
      // 添加请求信息到面包屑
      addBreadcrumb({
        message: `${req.method} ${req.url}`,
        category: "http",
        level: "info",
        data: {
          method: req.method,
          url: req.url,
          headers: Object.fromEntries(req.headers.entries()),
        },
      });

      // 设置请求上下文
      setContext("request", {
        method: req.method,
        url: req.url,
        headers: Object.fromEntries(req.headers.entries()),
      });

      const response = await handler(req);

      // 记录响应状态
      transaction.setHttpStatus(response.status);

      if (response.status >= 400) {
        addBreadcrumb({
          message: `Response ${response.status}`,
          category: "http",
          level: response.status >= 500 ? "error" : "warning",
          data: {
            status: response.status,
          },
        });
      }

      transaction.finish();
      return response;
    } catch (error) {
      // 捕获错误
      if (options?.captureErrors !== false) {
        captureException(
          error,
          `Error in ${options?.functionName || "edge-function"}`,
          "error",
        );
      }

      transaction.setStatus("internal_error");
      transaction.finish();

      // 返回错误响应
      return new Response(
        JSON.stringify({
          success: false,
          error: error instanceof Error ? error.message : "Internal server error",
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }
  };
}

/**
 * 报告性能问题
 */
export function reportPerformanceIssue(
  operation: string,
  duration: number,
  threshold = 3000,
) {
  if (duration > threshold) {
    captureMessage(
      `Slow operation: ${operation} took ${duration}ms`,
      "warning",
      {
        operation,
        duration_ms: duration,
        threshold_ms: threshold,
      },
    );
  }
}

/**
 * 报告数据库错误
 */
export function reportDatabaseError(
  error: unknown,
  query?: string,
  params?: unknown,
) {
  addBreadcrumb({
    message: "Database error",
    category: "database",
    level: "error",
    data: {
      query,
      params,
    },
  });

  captureException(error, "Database operation failed", "error");
}

/**
 * 报告外部 API 错误
 */
export function reportExternalApiError(
  error: unknown,
  url: string,
  method: string,
  statusCode?: number,
) {
  addBreadcrumb({
    message: `External API error: ${method} ${url}`,
    category: "http",
    level: "error",
    data: {
      url,
      method,
      status_code: statusCode,
    },
  });

  captureException(error, "External API request failed", "error");
}
