/**
 * Feedback Service
 * 反馈服务 - 处理用户反馈相关的业务逻辑
 */

import { UserFeedback } from "../domain/UserFeedback.ts";
import { IFeedbackRepository } from "../repositories/IFeedbackRepository.ts";
import { IContentRepository } from "../repositories/IContentRepository.ts";

export class FeedbackService {
  constructor(
    private readonly feedbackRepository: IFeedbackRepository,
    private readonly contentRepository: IContentRepository
  ) {}

  /**
   * 提交反馈
   */
  async submitFeedback(
    contentId: string,
    isHelpful: boolean,
    userId: string | null,
    comment: string | null,
    userAgent: string | null,
    ipAddress: string | null
  ): Promise<{ success: boolean; feedback?: UserFeedback; error?: string }> {
    // 验证内容是否存在
    const content = await this.contentRepository.findById(contentId);
    if (!content) {
      return { success: false, error: "Content not found" };
    }

    // 检查是否已经反馈过
    if (userId) {
      const hasSubmitted = await this.feedbackRepository.hasUserFeedback(
        contentId,
        userId
      );
      if (hasSubmitted) {
        return { success: false, error: "You have already submitted feedback" };
      }
    } else if (ipAddress) {
      const hasSubmitted = await this.feedbackRepository.hasIpFeedback(
        contentId,
        ipAddress
      );
      if (hasSubmitted) {
        return { success: false, error: "You have already submitted feedback" };
      }
    }

    // 创建反馈
    const feedbackData = UserFeedback.create(
      contentId,
      isHelpful,
      userId,
      comment,
      userAgent,
      ipAddress
    );

    try {
      const feedback = await this.feedbackRepository.create(feedbackData);
      return { success: true, feedback };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      };
    }
  }

  /**
   * 获取内容的反馈列表
   */
  async getContentFeedback(
    contentId: string,
    limit = 20,
    offset = 0
  ): Promise<UserFeedback[]> {
    return await this.feedbackRepository.findByContentId(
      contentId,
      limit,
      offset
    );
  }

  /**
   * 获取用户的反馈历史
   */
  async getUserFeedbackHistory(
    userId: string,
    limit = 20,
    offset = 0
  ): Promise<UserFeedback[]> {
    return await this.feedbackRepository.findByUserId(userId, limit, offset);
  }

  /**
   * 获取内容的反馈统计
   */
  async getContentFeedbackStats(contentId: string): Promise<{
    total: number;
    helpful: number;
    unhelpful: number;
    helpfulRate: number;
    sentiment: "positive" | "negative" | "neutral";
  }> {
    const stats = await this.feedbackRepository.getStatsByContentId(contentId);

    let sentiment: "positive" | "negative" | "neutral" = "neutral";
    if (stats.helpfulRate > 0.6) {
      sentiment = "positive";
    } else if (stats.helpfulRate < 0.4 && stats.total > 10) {
      sentiment = "negative";
    }

    return {
      ...stats,
      sentiment,
    };
  }

  /**
   * 分析反馈趋势
   */
  async analyzeFeedbackTrend(contentId: string): Promise<{
    needsImprovement: boolean;
    reason: string | null;
  }> {
    const stats = await this.getContentFeedbackStats(contentId);

    // 如果无用率超过60%且样本量足够，标记需要改进
    if (stats.unhelpful > stats.helpful && stats.total >= 10) {
      return {
        needsImprovement: true,
        reason: `High unhelpful rate: ${(
          (stats.unhelpful / stats.total) *
          100
        ).toFixed(1)}%`,
      };
    }

    return {
      needsImprovement: false,
      reason: null,
    };
  }

  /**
   * 获取需要改进的内容列表
   */
  async getContentNeedingImprovement(): Promise<string[]> {
    // 这里需要获取所有内容并分析，实际应该在数据库层面优化
    // 简化实现：返回空数组，实际应该通过视图或存储过程实现
    return [];
  }
}
