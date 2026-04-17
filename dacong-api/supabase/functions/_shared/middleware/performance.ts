/**
 * 性能追踪中间件
 * 记录 API 请求的响应时间和性能指标
 */

interface PerformanceMetric {
  endpoint: string;
  method: string;
  duration: number;
  status?: number;
  error?: boolean;
  timestamp: string;
  userAgent?: string;
  ip?: string;
}

interface PerformanceThresholds {
  warning: number;  // 警告阈值（毫秒）
  critical: number; // 严重阈值（毫秒）
}

const DEFAULT_THRESHOLDS: PerformanceThresholds = {
  warning: 1000,   // 1秒
  critical: 3000,  // 3秒
};

/**
 * 记录性能指标到 Supabase
 */
async function logPerformance(metric: PerformanceMetric): Promise<void> {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseKey) {
      console.error('Missing Supabase credentials for performance logging');
      return;
    }

    // 异步写入，不阻塞主请求
    fetch(`${supabaseUrl}/rest/v1/performance_metrics`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`,
      },
      body: JSON.stringify({
        service: 'api',
        metric_name: 'http_request_duration',
        metric_value: metric.duration,
        tags: {
          endpoint: metric.endpoint,
          method: metric.method,
          status: metric.status,
          error: metric.error || false,
          user_agent: metric.userAgent,
          ip: metric.ip,
        },
      }),
    }).catch(err => {
      console.error('Failed to log performance metric:', err);
    });

    // 如果超过阈值，记录到控制台
    if (metric.duration > DEFAULT_THRESHOLDS.critical) {
      console.error(`🔴 CRITICAL: Slow request detected`, metric);
    } else if (metric.duration > DEFAULT_THRESHOLDS.warning) {
      console.warn(`🟡 WARNING: Slow request detected`, metric);
    }
  } catch (error) {
    console.error('Error in logPerformance:', error);
  }
}

/**
 * 性能追踪中间件
 */
export function performanceMiddleware(thresholds: PerformanceThresholds = DEFAULT_THRESHOLDS) {
  return async (req: Request, handler: Function): Promise<Response> => {
    const startTime = Date.now();
    const url = new URL(req.url);
    const endpoint = url.pathname;
    const method = req.method;
    const userAgent = req.headers.get('user-agent') || undefined;
    const ip = req.headers.get('x-forwarded-for') || req.headers.get('x-real-ip') || undefined;

    try {
      const response = await handler(req);
      const duration = Date.now() - startTime;

      // 记录性能指标
      logPerformance({
        endpoint,
        method,
        duration,
        status: response.status,
        timestamp: new Date().toISOString(),
        userAgent,
        ip,
      });

      // 添加性能头到响应
      const headers = new Headers(response.headers);
      headers.set('X-Response-Time', `${duration}ms`);
      headers.set('X-Performance-Status', duration > thresholds.critical ? 'critical' :
                                          duration > thresholds.warning ? 'warning' : 'ok');

      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers,
      });
    } catch (error) {
      const duration = Date.now() - startTime;

      // 记录错误性能指标
      logPerformance({
        endpoint,
        method,
        duration,
        error: true,
        timestamp: new Date().toISOString(),
        userAgent,
        ip,
      });

      throw error;
    }
  };
}

/**
 * 获取性能统计
 */
export async function getPerformanceStats(timeRange: string = '1h'): Promise<any> {
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (!supabaseUrl || !supabaseKey) {
    throw new Error('Missing Supabase credentials');
  }

  const response = await fetch(
    `${supabaseUrl}/rest/v1/rpc/get_performance_stats?time_range=${timeRange}`,
    {
      headers: {
        'apikey': supabaseKey,
        'Authorization': `Bearer ${supabaseKey}`,
      },
    }
  );

  if (!response.ok) {
    throw new Error(`Failed to fetch performance stats: ${response.statusText}`);
  }

  return response.json();
}
