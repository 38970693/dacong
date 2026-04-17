/**
 * Simple In-Memory Cache Utility
 * 简单的内存缓存工具
 */

interface CacheEntry<T> {
  data: T;
  expiresAt: number;
}

export class Cache<T> {
  private store: Map<string, CacheEntry<T>> = new Map();

  /**
   * 设置缓存
   * @param key 缓存键
   * @param data 缓存数据
   * @param ttlSeconds 过期时间（秒）
   */
  set(key: string, data: T, ttlSeconds: number): void {
    const expiresAt = Date.now() + ttlSeconds * 1000;
    this.store.set(key, { data, expiresAt });
  }

  /**
   * 获取缓存
   * @param key 缓存键
   * @returns 缓存数据或null
   */
  get(key: string): T | null {
    const entry = this.store.get(key);

    if (!entry) {
      return null;
    }

    // 检查是否过期
    if (Date.now() > entry.expiresAt) {
      this.store.delete(key);
      return null;
    }

    return entry.data;
  }

  /**
   * 删除缓存
   * @param key 缓存键
   */
  delete(key: string): void {
    this.store.delete(key);
  }

  /**
   * 清空所有缓存
   */
  clear(): void {
    this.store.clear();
  }

  /**
   * 清理过期缓存
   */
  cleanup(): void {
    const now = Date.now();
    for (const [key, entry] of this.store.entries()) {
      if (now > entry.expiresAt) {
        this.store.delete(key);
      }
    }
  }

  /**
   * 获取缓存大小
   */
  size(): number {
    return this.store.size;
  }
}

/**
 * 全局缓存实例
 */
export const globalCache = new Cache<unknown>();
