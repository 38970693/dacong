/**
 * Recommendation Service
 * 推荐服务 - 处理推荐相关的业务逻辑
 */

import { Recommendation } from "../domain/Recommendation.ts";
import { Content, Scenario } from "../domain/Content.ts";
import { IRecommendationRepository } from "../repositories/IRecommendationRepository.ts";
import { IContentRepository } from "../repositories/IContentRepository.ts";
import { Cache } from "../utils/cache.ts";

interface RecommendationWithScore {
  recommendation: Recommendation;
  content: Content;
  score: number;
}

export class RecommendationService {
  private cache: Cache<Content[]>;
  private readonly CACHE_TTL = 300; // 5分钟缓存

  constructor(
    private readonly recommendationRepository: IRecommendationRepository,
    private readonly contentRepository: IContentRepository
  ) {
    this.cache = new Cache<Content[]>();
  }

  /**
   * 获取场景推荐（包含完整内容）- 带缓存和智能排序
   */
  async getRecommendationsWithContent(
    scenario: Scenario,
    limit = 20
  ): Promise<Content[]> {
    // 尝试从缓存获取
    const cacheKey = `recommendations:${scenario}:${limit}`;
    const cached = this.cache.get(cacheKey);
    if (cached) {
      return cached;
    }

    // 获取推荐配置
    const recommendations = await this.recommendationRepository.findByScenario(
      scenario
    );

    if (recommendations.length === 0) {
      return [];
    }

    // 获取内容并计算推荐分数
    const withScores: RecommendationWithScore[] = [];
    for (const recommendation of recommendations) {
      const content = await this.contentRepository.findById(
        recommendation.contentId
      );
      if (content) {
        const score = this.calculateRecommendationScore(
          recommendation,
          content
        );
        withScores.push({ recommendation, content, score });
      }
    }

    // 按分数排序并限制数量
    const sorted = withScores
      .sort((a, b) => {
        // 首先按rank排序（最佳、平替、免费）
        if (a.recommendation.rank !== b.recommendation.rank) {
          return a.recommendation.rank - b.recommendation.rank;
        }
        // 相同rank按分数排序
        return b.score - a.score;
      })
      .slice(0, limit)
      .map((item) => item.content);

    // 缓存结果
    this.cache.set(cacheKey, sorted, this.CACHE_TTL);

    return sorted;
  }

  /**
   * 计算推荐分数
   * 综合考虑：用户反馈、浏览量、分享量
   */
  private calculateRecommendationScore(
    recommendation: Recommendation,
    content: Content
  ): number {
    let score = 0;

    // 基础分：根据rank
    if (recommendation.isBest()) {
      score += 1000;
    } else if (recommendation.isAlternative()) {
      score += 500;
    } else if (recommendation.isFree()) {
      score += 300;
    }

    // 用户反馈分（权重最高）
    const helpfulRate = content.helpfulRate;
    if (helpfulRate !== null) {
      score += helpfulRate * 200; // 最高200分
    }

    // 浏览量分（归一化）
    score += Math.min(content.viewCount / 10, 100); // 最高100分

    // 分享量分（归一化）
    score += Math.min(content.shareCount * 5, 50); // 最高50分

    // 有用数分（归一化）
    score += Math.min(content.helpfulCount / 2, 50); // 最高50分

    return score;
  }

  /**
   * 获取场景推荐（旧版本，保持兼容）
   */
  async getRecommendationsWithContentLegacy(
    scenario: Scenario
  ): Promise<Array<{ recommendation: Recommendation; content: Content }>> {
    const recommendations = await this.recommendationRepository.findByScenario(
      scenario
    );

    const results = [];
    for (const recommendation of recommendations) {
      const content = await this.contentRepository.findById(
        recommendation.contentId
      );
      if (content) {
        results.push({ recommendation, content });
      }
    }

    return results;
  }

  /**
   * 获取最佳推荐
   */
  async getBestRecommendation(scenario: Scenario): Promise<Content | null> {
    const recommendations = await this.recommendationRepository.findByScenario(
      scenario
    );

    const best = recommendations.find((r) => r.isBest());
    if (!best) return null;

    return await this.contentRepository.findById(best.contentId);
  }

  /**
   * 获取平替推荐
   */
  async getAlternativeRecommendations(
    scenario: Scenario
  ): Promise<Content[]> {
    const recommendations = await this.recommendationRepository.findByScenario(
      scenario
    );

    const alternatives = recommendations.filter((r) => r.isAlternative());
    const contents = [];

    for (const rec of alternatives) {
      const content = await this.contentRepository.findById(rec.contentId);
      if (content) contents.push(content);
    }

    return contents;
  }

  /**
   * 获取免费推荐
   */
  async getFreeRecommendations(scenario: Scenario): Promise<Content[]> {
    const recommendations = await this.recommendationRepository.findByScenario(
      scenario
    );

    const freeRecs = recommendations.filter((r) => r.isFree());
    const contents = [];

    for (const rec of freeRecs) {
      const content = await this.contentRepository.findById(rec.contentId);
      if (content) contents.push(content);
    }

    return contents;
  }

  /**
   * 获取所有激活的推荐
   */
  async getAllActiveRecommendations(): Promise<Recommendation[]> {
    return await this.recommendationRepository.findAllActive();
  }

  /**
   * 验证推荐配置的完整性
   */
  async validateRecommendationIntegrity(
    scenario: Scenario
  ): Promise<{ valid: boolean; errors: string[] }> {
    const recommendations = await this.recommendationRepository.findByScenario(
      scenario
    );

    const errors: string[] = [];

    // 检查是否有最佳推荐
    if (!recommendations.some((r) => r.isBest())) {
      errors.push(`Scenario ${scenario} missing best recommendation (rank 1)`);
    }

    // 检查关联的内容是否存在
    for (const rec of recommendations) {
      const content = await this.contentRepository.findById(rec.contentId);
      if (!content) {
        errors.push(
          `Recommendation ${rec.id} references non-existent content ${rec.contentId}`
        );
      }
    }

    return {
      valid: errors.length === 0,
      errors,
    };
  }
}
