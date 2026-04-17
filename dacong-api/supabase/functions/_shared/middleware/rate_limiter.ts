/**
 * API 限流中间件
 * 使用 Token Bucket 算法实现速率限制
 */

interface RateLimitConfig {
  maxRequests: number; // 最大请求数
  windowMs: number; // 时间窗口（毫秒）
  message?: string; // 限流提示信息
}

interface RateLimitStore {
  count: number;
  resetTime: number;
}

// 内存存储（生产环境建议使用 Redis）
const store = new Map<string, RateLimitStore>();

/**
 * 创建限流中间件
 */
export function createRateLimiter(config: RateLimitConfig) {
  const {
    maxRequests,
    windowMs,
    message = 'Too many requests, please try again later.',
  } = config;

  return async (req: Request): Promise<Response | null> => {
    // 获取客户端标识（IP 或用户 ID）
    const identifier = getClientIdentifier(req);

    // 获取当前时间
    const now = Date.now();

    // 获取或创建限流记录
    let record = store.get(identifier);

    // 如果记录不存在或已过期，创建新记录
    if (!record || now > record.resetTime) {
      record = {
        count: 0,
        resetTime: now + windowMs,
      };
      store.set(identifier, record);
    }

    // 增加请求计数
    record.count++;

    // 检查是否超过限制
    if (record.count > maxRequests) {
      const retryAfter = Math.ceil((record.resetTime - now) / 1000);

      return new Response(
        JSON.stringify({
          success: false,
          error: message,
          retryAfter,
        }),
        {
          status: 429,
          headers: {
            'Content-Type': 'application/json',
            'Retry-After': retryAfter.toString(),
            'X-RateLimit-Limit': maxRequests.toString(),
            'X-RateLimit-Remaining': '0',
            'X-RateLimit-Reset': record.resetTime.toString(),
          },
        }
      );
    }

    // 返回 null 表示通过限流检查
    return null;
  };
}

/**
 * 获取客户端标识
 */
function getClientIdentifier(req: Request): string {
  // 优先使用用户 ID
  const authHeader = req.headers.get('Authorization');
  if (authHeader) {
    const token = authHeader.replace('Bearer ', '');
    // 这里可以解析 JWT 获取用户 ID
    // 简化处理，直接使用 token
    return `user:${token.substring(0, 20)}`;
  }

  // 使用 IP 地址
  const ip =
    req.headers.get('x-forwarded-for') ||
    req.headers.get('x-real-ip') ||
    'unknown';

  return `ip:${ip}`;
}

/**
 * 清理过期记录（定期调用）
 */
export function cleanupExpiredRecords() {
  const now = Date.now();
  for (const [key, record] of store.entries()) {
    if (now > record.resetTime) {
      store.delete(key);
    }
  }
}

/**
 * 预定义的限流配置
 */
export const RateLimitPresets = {
  // 严格限流：每分钟 10 次
  strict: {
    maxRequests: 10,
    windowMs: 60 * 1000,
  },
  // 标准限流：每分钟 30 次
  standard: {
    maxRequests: 30,
    windowMs: 60 * 1000,
  },
  // 宽松限流：每分钟 100 次
  relaxed: {
    maxRequests: 100,
    windowMs: 60 * 1000,
  },
  // 搜索限流：每分钟 20 次
  search: {
    maxRequests: 20,
    windowMs: 60 * 1000,
    message: 'Search rate limit exceeded. Please slow down.',
  },
  // 反馈限流：每小时 10 次
  feedback: {
    maxRequests: 10,
    windowMs: 60 * 60 * 1000,
    message: 'Feedback submission limit reached. Please try again later.',
  },
};

/**
 * 使用示例：
 * 
 * import { createRateLimiter, RateLimitPresets } from './_shared/middleware/rate_limiter.ts';
 * 
 * const rateLimiter = createRateLimiter(RateLimitPresets.standard);
 * 
 * Deno.serve(async (req) => {
 *   // 应用限流
 *   const rateLimitResponse = await rateLimiter(req);
 *   if (rateLimitResponse) {
 *     return rateLimitResponse;
 *   }
 * 
 *   // 处理正常请求
 *   return new Response('OK');
 * });
 */
