/**
 * Content Repository Interface
 * 内容仓储接口 - 定义内容数据访问的抽象
 */

import { Content, Scenario } from "../domain/Content.ts";

export interface IContentRepository {
  /**
   * 根据ID查找内容
   */
  findById(id: string): Promise<Content | null>;

  /**
   * 根据场景查找推荐内容
   */
  findByScenario(scenario: Scenario, limit?: number): Promise<Content[]>;

  /**
   * 搜索内容
   */
  search(
    query: string,
    language: "zh" | "en",
    limit?: number,
    offset?: number
  ): Promise<Content[]>;

  /**
   * 获取热门内容
   */
  findPopular(limit?: number): Promise<Content[]>;

  /**
   * 获取最新内容
   */
  findRecent(limit?: number): Promise<Content[]>;

  /**
   * 更新浏览次数
   */
  incrementViewCount(id: string): Promise<void>;

  /**
   * 更新分享次数
   */
  incrementShareCount(id: string): Promise<void>;

  /**
   * 获取内容总数
   */
  count(): Promise<number>;
}
