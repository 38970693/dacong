/**
 * Cache Middleware
 * 缓存中间件 - HTTP 响应缓存
 */

import { ICache } from "../core/ICache.ts";

export interface CacheMiddlewareOptions {
  ttl?: number; // 缓存时间（秒）
  prefix?: string; // 键前缀
  keyGenerator?: (req: Request) => string; // 自定义键生成器
  shouldCache?: (req: Request, res: Response) => boolean; // 是否应该缓存
}

/**
 * 创建缓存中间件
 * 自动缓存 GET 请求的响应
 */
export function createCacheMiddleware(
  cache: ICache,
  options: CacheMiddlewareOptions = {}
) {
  const {
    ttl = 300,
    prefix = "http",
    keyGenerator = defaultKeyGenerator,
    shouldCache = defaultShouldCache,
  } = options;

  return async (req: Request, next: () => Promise<Response>): Promise<Response> => {
    // 只缓存 GET 请求
    if (req.method !== "GET") {
      return await next();
    }

    // 生成缓存键
    const cacheKey = keyGenerator(req);
    const fullKey = `${prefix}:${cacheKey}`;

    // 尝试从缓存获取
    const cached = await cache.get<CachedResponse>(fullKey);
    if (cached) {
      return new Response(cached.body, {
        status: cached.status,
        headers: {
          ...cached.headers,
          "X-Cache": "HIT",
        },
      });
    }

    // 执行请求
    const response = await next();

    // 检查是否应该缓存
    if (!shouldCache(req, response)) {
      return response;
    }

    // 读取响应体
    const body = await response.text();

    // 存入缓存
    const cachedResponse: CachedResponse = {
      body,
      status: response.status,
      headers: Object.fromEntries(response.headers.entries()),
    };

    await cache.set(fullKey, cachedResponse, { ttl });

    // 返回新的响应（添加缓存标记）
    return new Response(body, {
      status: response.status,
      headers: {
        ...cachedResponse.headers,
        "X-Cache": "MISS",
      },
    });
  };
}

/**
 * 缓存的响应结构
 */
interface CachedResponse {
  body: string;
  status: number;
  headers: Record<string, string>;
}

/**
 * 默认键生成器
 * 使用 URL 和查询参数生成键
 */
function defaultKeyGenerator(req: Request): string {
  const url = new URL(req.url);
  return `${url.pathname}${url.search}`;
}

/**
 * 默认缓存判断
 * 只缓存成功的响应
 */
function defaultShouldCache(_req: Request, res: Response): boolean {
  return res.status === 200;
}

/**
 * 创建缓存失效中间件
 * 在写操作后自动清除相关缓存
 */
export function createCacheInvalidationMiddleware(
  cache: ICache,
  patterns: string[]
) {
  return async (req: Request, next: () => Promise<Response>): Promise<Response> => {
    // 执行请求
    const response = await next();

    // 如果是写操作且成功，清除缓存
    if (
      ["POST", "PUT", "PATCH", "DELETE"].includes(req.method) &&
      response.status >= 200 &&
      response.status < 300
    ) {
      for (const pattern of patterns) {
        await cache.delPattern(pattern);
      }
    }

    return response;
  };
}
