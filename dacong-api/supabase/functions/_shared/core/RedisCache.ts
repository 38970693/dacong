/**
 * Redis Cache Implementation
 * Redis 缓存实现 - 生产环境使用
 */

import { connect, Redis } from "https://deno.land/x/redis@v0.31.0/mod.ts";
import { ICache, ICacheOptions, ICacheStats } from "./ICache.ts";

export interface RedisCacheConfig {
  hostname: string;
  port: number;
  password?: string;
  db?: number;
  maxRetryCount?: number;
  retryInterval?: number;
}

/**
 * Redis 缓存实现
 * 特性：
 * - 持久化存储
 * - 分布式支持
 * - LRU 淘汰策略
 * - 高性能
 */
export class RedisCache implements ICache {
  private redis: Redis | null = null;
  private config: RedisCacheConfig;
  private connected = false;
  private stats = {
    hits: 0,
    misses: 0,
  };

  constructor(config: RedisCacheConfig) {
    this.config = config;
  }

  /**
   * 连接到 Redis
   */
  async connect(): Promise<void> {
    if (this.connected) return;

    try {
      this.redis = await connect({
        hostname: this.config.hostname,
        port: this.config.port,
        password: this.config.password,
        db: this.config.db,
        maxRetryCount: this.config.maxRetryCount ?? 3,
      });
      this.connected = true;
      console.log(`[RedisCache] Connected to ${this.config.hostname}:${this.config.port}`);
    } catch (error) {
      console.error("[RedisCache] Connection failed:", error);
      throw new Error(`Failed to connect to Redis: ${error.message}`);
    }
  }

  /**
   * 确保已连接
   */
  private ensureConnected(): void {
    if (!this.connected || !this.redis) {
      throw new Error("Redis not connected. Call connect() first.");
    }
  }

  /**
   * 生成带前缀的键
   */
  private getKey(key: string, prefix?: string): string {
    return prefix ? `${prefix}:${key}` : key;
  }

  /**
   * 获取缓存值
   */
  async get<T>(key: string): Promise<T | null> {
    this.ensureConnected();

    try {
      const value = await this.redis!.get(key);

      if (value === null || value === undefined) {
        this.stats.misses++;
        return null;
      }

      this.stats.hits++;
      return JSON.parse(value) as T;
    } catch (error) {
      console.error(`[RedisCache] Get error for key ${key}:`, error);
      this.stats.misses++;
      return null;
    }
  }

  /**
   * 设置缓存值
   */
  async set<T>(key: string, value: T, options?: ICacheOptions): Promise<void> {
    this.ensureConnected();

    try {
      const finalKey = this.getKey(key, options?.prefix);
      const serialized = JSON.stringify(value);

      if (options?.ttl) {
        await this.redis!.setex(finalKey, options.ttl, serialized);
      } else {
        await this.redis!.set(finalKey, serialized);
      }
    } catch (error) {
      console.error(`[RedisCache] Set error for key ${key}:`, error);
      throw error;
    }
  }

  /**
   * 删除缓存
   */
  async del(key: string): Promise<void> {
    this.ensureConnected();

    try {
      await this.redis!.del(key);
    } catch (error) {
      console.error(`[RedisCache] Delete error for key ${key}:`, error);
      throw error;
    }
  }

  /**
   * 批量删除缓存（支持模式匹配）
   */
  async delPattern(pattern: string): Promise<number> {
    this.ensureConnected();

    try {
      const keys = await this.redis!.keys(pattern);
      if (keys.length === 0) return 0;

      await this.redis!.del(...keys);
      return keys.length;
    } catch (error) {
      console.error(`[RedisCache] Delete pattern error for ${pattern}:`, error);
      throw error;
    }
  }

  /**
   * 检查键是否存在
   */
  async exists(key: string): Promise<boolean> {
    this.ensureConnected();

    try {
      const result = await this.redis!.exists(key);
      return result === 1;
    } catch (error) {
      console.error(`[RedisCache] Exists error for key ${key}:`, error);
      return false;
    }
  }

  /**
   * 设置过期时间
   */
  async expire(key: string, seconds: number): Promise<boolean> {
    this.ensureConnected();

    try {
      const result = await this.redis!.expire(key, seconds);
      return result === 1;
    } catch (error) {
      console.error(`[RedisCache] Expire error for key ${key}:`, error);
      return false;
    }
  }

  /**
   * 获取剩余过期时间
   */
  async ttl(key: string): Promise<number> {
    this.ensureConnected();

    try {
      return await this.redis!.ttl(key);
    } catch (error) {
      console.error(`[RedisCache] TTL error for key ${key}:`, error);
      return -1;
    }
  }

  /**
   * 获取缓存统计信息
   */
  async getStats(): Promise<ICacheStats> {
    this.ensureConnected();

    try {
      const info = await this.redis!.info("stats");
      const memory = await this.redis!.info("memory");
      const dbsize = await this.redis!.dbsize();

      // 解析 Redis INFO 输出
      const statsMatch = info.match(/keyspace_hits:(\d+)/);
      const missesMatch = info.match(/keyspace_misses:(\d+)/);
      const memoryMatch = memory.match(/used_memory:(\d+)/);

      const hits = statsMatch ? parseInt(statsMatch[1]) : this.stats.hits;
      const misses = missesMatch ? parseInt(missesMatch[1]) : this.stats.misses;
      const usedMemory = memoryMatch ? parseInt(memoryMatch[1]) : 0;

      const total = hits + misses;
      const hitRate = total > 0 ? (hits / total) * 100 : 0;

      return {
        hits,
        misses,
        keys: dbsize,
        memory: usedMemory,
        hitRate: Math.round(hitRate * 100) / 100,
      };
    } catch (error) {
      console.error("[RedisCache] Get stats error:", error);
      return {
        hits: this.stats.hits,
        misses: this.stats.misses,
        keys: 0,
        memory: 0,
        hitRate: 0,
      };
    }
  }

  /**
   * 清空所有缓存
   */
  async flush(): Promise<void> {
    this.ensureConnected();

    try {
      await this.redis!.flushdb();
      this.stats.hits = 0;
      this.stats.misses = 0;
    } catch (error) {
      console.error("[RedisCache] Flush error:", error);
      throw error;
    }
  }

  /**
   * 关闭连接
   */
  async close(): Promise<void> {
    if (this.redis) {
      try {
        await this.redis.quit();
        this.connected = false;
        console.log("[RedisCache] Connection closed");
      } catch (error) {
        console.error("[RedisCache] Close error:", error);
      }
    }
  }
}

/**
 * 从环境变量创建 Redis 缓存实例
 */
export function createRedisCacheFromEnv(): RedisCache {
  const redisUrl = Deno.env.get("REDIS_URL");

  if (!redisUrl) {
    throw new Error("REDIS_URL environment variable is required");
  }

  // 解析 Redis URL: redis://[:password@]host:port[/db]
  const url = new URL(redisUrl);

  const config: RedisCacheConfig = {
    hostname: url.hostname,
    port: parseInt(url.port) || 6379,
    password: url.password || undefined,
    db: url.pathname ? parseInt(url.pathname.slice(1)) : 0,
  };

  return new RedisCache(config);
}
