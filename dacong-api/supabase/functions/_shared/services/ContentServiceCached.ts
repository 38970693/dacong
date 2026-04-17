/**
 * Content Service with Redis Cache
 * 内容服务 - 集成 Redis 缓存示例
 */

import { IContentRepository } from "../repositories/IContentRepository.ts";
import { Content } from "../domain/Content.ts";
import { ICache } from "../core/ICache.ts";

export class ContentService {
  constructor(
    private readonly contentRepository: IContentRepository,
    private readonly cache?: ICache | null
  ) {}

  /**
   * 获取内容详情（带缓存）
   */
  async getContentById(id: string): Promise<Content | null> {
    const cacheKey = `content:${id}`;

    // 尝试从缓存获取
    if (this.cache) {
      const cached = await this.cache.get<Content>(cacheKey);
      if (cached) {
        console.log(`[ContentService] Cache HIT: ${cacheKey}`);
        return cached;
      }
      console.log(`[ContentService] Cache MISS: ${cacheKey}`);
    }

    // 从数据库获取
    const content = await this.contentRepository.findById(id);

    // 存入缓存
    if (content && this.cache) {
      await this.cache.set(cacheKey, content, { ttl: 300 }); // 5分钟
    }

    return content;
  }

  /**
   * 获取热门内容（带缓存）
   */
  async getHotContents(limit = 50): Promise<Content[]> {
    const cacheKey = `content:hot:${limit}`;

    // 尝试从缓存获取
    if (this.cache) {
      const cached = await this.cache.get<Content[]>(cacheKey);
      if (cached) {
        console.log(`[ContentService] Cache HIT: ${cacheKey}`);
        return cached;
      }
      console.log(`[ContentService] Cache MISS: ${cacheKey}`);
    }

    // 从数据库获取
    const contents = await this.contentRepository.findHot(limit);

    // 存入缓存
    if (this.cache) {
      await this.cache.set(cacheKey, contents, { ttl: 300 }); // 5分钟
    }

    return contents;
  }

  /**
   * 搜索内容（带缓存）
   */
  async searchContents(
    query: string,
    filters?: Record<string, unknown>
  ): Promise<Content[]> {
    const cacheKey = `content:search:${query}:${JSON.stringify(filters)}`;

    // 尝试从缓存获取
    if (this.cache) {
      const cached = await this.cache.get<Content[]>(cacheKey);
      if (cached) {
        console.log(`[ContentService] Cache HIT: ${cacheKey}`);
        return cached;
      }
      console.log(`[ContentService] Cache MISS: ${cacheKey}`);
    }

    // 从数据库搜索
    const contents = await this.contentRepository.search(query, filters);

    // 存入缓存
    if (this.cache) {
      await this.cache.set(cacheKey, contents, { ttl: 600 }); // 10分钟
    }

    return contents;
  }

  /**
   * 更新内容（清除缓存）
   */
  async updateContent(
    id: string,
    data: Partial<Content>
  ): Promise<Content | null> {
    // 更新数据库
    const updated = await this.contentRepository.update(id, data);

    // 清除相关缓存
    if (this.cache) {
      await this.cache.del(`content:${id}`);
      await this.cache.delPattern("content:hot:*");
      await this.cache.delPattern("content:search:*");
      console.log(`[ContentService] Cache invalidated for content:${id}`);
    }

    return updated;
  }

  /**
   * 删除内容（清除缓存）
   */
  async deleteContent(id: string): Promise<void> {
    // 删除数据库记录
    await this.contentRepository.delete(id);

    // 清除相关缓存
    if (this.cache) {
      await this.cache.del(`content:${id}`);
      await this.cache.delPattern("content:hot:*");
      await this.cache.delPattern("content:search:*");
      console.log(`[ContentService] Cache invalidated for content:${id}`);
    }
  }

  /**
   * 批量获取内容（带缓存）
   */
  async getContentsByIds(ids: string[]): Promise<Content[]> {
    const results: Content[] = [];
    const missingIds: string[] = [];

    // 尝试从缓存获取
    if (this.cache) {
      for (const id of ids) {
        const cached = await this.cache.get<Content>(`content:${id}`);
        if (cached) {
          results.push(cached);
        } else {
          missingIds.push(id);
        }
      }
    } else {
      missingIds.push(...ids);
    }

    // 从数据库获取缺失的内容
    if (missingIds.length > 0) {
      const contents = await this.contentRepository.findByIds(missingIds);

      // 存入缓存
      if (this.cache) {
        for (const content of contents) {
          await this.cache.set(`content:${content.id}`, content, { ttl: 300 });
        }
      }

      results.push(...contents);
    }

    return results;
  }
}
