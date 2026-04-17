/**
 * Recommendation Repository Interface
 * 推荐仓储接口 - 定义推荐数据访问的抽象
 */

import { Recommendation } from "../domain/Recommendation.ts";

export interface IRecommendationRepository {
  /**
   * 根据场景查找推荐配置
   */
  findByScenario(scenario: string): Promise<Recommendation[]>;

  /**
   * 根据ID查找推荐
   */
  findById(id: string): Promise<Recommendation | null>;

  /**
   * 创建推荐配置
   */
  create(recommendation: Omit<Recommendation, "id" | "createdAt" | "updatedAt">): Promise<Recommendation>;

  /**
   * 更新推荐配置
   */
  update(id: string, data: Partial<Recommendation>): Promise<Recommendation>;

  /**
   * 删除推荐配置
   */
  delete(id: string): Promise<void>;

  /**
   * 获取所有激活的推荐
   */
  findAllActive(): Promise<Recommendation[]>;
}
