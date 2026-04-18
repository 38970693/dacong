/**
 * Content Service
 * 内容服务 - 处理内容相关的业务逻辑
 */

import { Content, Scenario } from "../domain/Content.ts";
import { IContentRepository } from "../repositories/IContentRepository.ts";

export class ContentService {
  constructor(private readonly contentRepository: IContentRepository) {}

  /**
   * 获取内容详情
   */
  async getContentDetail(
    id: string,
    incrementView = true
  ): Promise<Content | null> {
    const content = await this.contentRepository.findById(id);

    if (!content) {
      return null;
    }

    // 增加浏览次数
    if (incrementView) {
      await this.contentRepository.incrementViewCount(id);
    }

    return content;
  }

  /**
   * 根据场景获取推荐内容
   */
  async getRecommendationsByScenario(
    scenario: Scenario,
    limit = 20
  ): Promise<Content[]> {
    return await this.contentRepository.findByScenario(scenario, limit);
  }

  /**
   * 搜索内容
   */
  async searchContent(
    query: string,
    language: "zh" | "en" = "zh",
    limit = 20,
    offset = 0,
    filters?: {
      scenario?: string;
      isFree?: boolean;
      availableInChina?: boolean;
    },
    sortBy: "relevance" | "rating" | "viewCount" = "relevance"
  ): Promise<{ items: Content[]; total: number }> {
    const items = await this.contentRepository.search(
      query,
      language,
      limit,
      offset,
      filters,
      sortBy
    );
    const total = await this.contentRepository.count();

    return { items, total };
  }

  /**
   * 获取热门内容
   */
  async getPopularContent(limit = 10): Promise<Content[]> {
    return await this.contentRepository.findPopular(limit);
  }

  /**
   * 获取最新内容
   */
  async getRecentContent(limit = 10): Promise<Content[]> {
    return await this.contentRepository.findRecent(limit);
  }

  /**
   * 分享内容
   */
  async shareContent(id: string): Promise<void> {
    const content = await this.contentRepository.findById(id);
    if (!content) {
      throw new Error("Content not found");
    }

    await this.contentRepository.incrementShareCount(id);
  }

  /**
   * 验证内容是否存在
   */
  async validateContentExists(id: string): Promise<boolean> {
    const content = await this.contentRepository.findById(id);
    return content !== null;
  }
}
