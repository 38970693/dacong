/**
 * Cache Decorator
 * 缓存装饰器 - 自动缓存函数结果
 */

import { ICache } from "../core/ICache.ts";

export interface CacheDecoratorOptions {
  ttl?: number; // 缓存时间（秒）
  prefix?: string; // 键前缀
  keyGenerator?: (...args: unknown[]) => string; // 自定义键生成器
}

/**
 * 缓存装饰器
 * 自动缓存异步函数的返回值
 *
 * @example
 * ```typescript
 * class UserService {
 *   @Cacheable({ ttl: 300, prefix: 'user' })
 *   async getUser(id: string) {
 *     return await db.users.findById(id);
 *   }
 * }
 * ```
 */
export function Cacheable(cache: ICache, options: CacheDecoratorOptions = {}) {
  return function (
    _target: unknown,
    _propertyKey: string,
    descriptor: PropertyDescriptor
  ) {
    const originalMethod = descriptor.value;

    descriptor.value = async function (...args: unknown[]) {
      // 生成缓存键
      const cacheKey = options.keyGenerator
        ? options.keyGenerator(...args)
        : generateDefaultKey(_propertyKey, args);

      const fullKey = options.prefix ? `${options.prefix}:${cacheKey}` : cacheKey;

      // 尝试从缓存获取
      const cached = await cache.get(fullKey);
      if (cached !== null) {
        return cached;
      }

      // 执行原始方法
      const result = await originalMethod.apply(this, args);

      // 存入缓存
      await cache.set(fullKey, result, { ttl: options.ttl });

      return result;
    };

    return descriptor;
  };
}

/**
 * 缓存失效装饰器
 * 在方法执行后自动清除相关缓存
 *
 * @example
 * ```typescript
 * class UserService {
 *   @CacheEvict({ pattern: 'user:*' })
 *   async updateUser(id: string, data: UpdateUserDto) {
 *     return await db.users.update(id, data);
 *   }
 * }
 * ```
 */
export function CacheEvict(cache: ICache, pattern: string) {
  return function (
    _target: unknown,
    _propertyKey: string,
    descriptor: PropertyDescriptor
  ) {
    const originalMethod = descriptor.value;

    descriptor.value = async function (...args: unknown[]) {
      // 执行原始方法
      const result = await originalMethod.apply(this, args);

      // 清除缓存
      await cache.delPattern(pattern);

      return result;
    };

    return descriptor;
  };
}

/**
 * 生成默认缓存键
 */
function generateDefaultKey(methodName: string, args: unknown[]): string {
  const argsKey = args.length > 0 ? JSON.stringify(args) : "no-args";
  return `${methodName}:${argsKey}`;
}

/**
 * 缓存包装函数
 * 用于包装普通函数，添加缓存功能
 */
export function withCache<T extends (...args: unknown[]) => Promise<unknown>>(
  cache: ICache,
  fn: T,
  options: CacheDecoratorOptions = {}
): T {
  return (async (...args: unknown[]) => {
    const cacheKey = options.keyGenerator
      ? options.keyGenerator(...args)
      : generateDefaultKey(fn.name, args);

    const fullKey = options.prefix ? `${options.prefix}:${cacheKey}` : cacheKey;

    // 尝试从缓存获取
    const cached = await cache.get(fullKey);
    if (cached !== null) {
      return cached;
    }

    // 执行原始函数
    const result = await fn(...args);

    // 存入缓存
    await cache.set(fullKey, result, { ttl: options.ttl });

    return result;
  }) as T;
}
