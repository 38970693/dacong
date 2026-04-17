/**
 * Cache Interface
 * 缓存接口 - 定义统一的缓存操作规范
 */

export interface ICacheOptions {
  ttl?: number; // Time to live in seconds
  prefix?: string; // Key prefix for namespacing
}

export interface ICacheStats {
  hits: number;
  misses: number;
  keys: number;
  memory: number;
  hitRate: number;
}

/**
 * 缓存接口
 * 支持 Redis、内存缓存等多种实现
 */
export interface ICache {
  /**
   * 获取缓存值
   */
  get<T>(key: string): Promise<T | null>;

  /**
   * 设置缓存值
   */
  set<T>(key: string, value: T, options?: ICacheOptions): Promise<void>;

  /**
   * 删除缓存
   */
  del(key: string): Promise<void>;

  /**
   * 批量删除缓存（支持模式匹配）
   */
  delPattern(pattern: string): Promise<number>;

  /**
   * 检查键是否存在
   */
  exists(key: string): Promise<boolean>;

  /**
   * 设置过期时间
   */
  expire(key: string, seconds: number): Promise<boolean>;

  /**
   * 获取剩余过期时间
   */
  ttl(key: string): Promise<number>;

  /**
   * 获取缓存统计信息
   */
  getStats(): Promise<ICacheStats>;

  /**
   * 清空所有缓存
   */
  flush(): Promise<void>;

  /**
   * 关闭连接
   */
  close(): Promise<void>;
}
