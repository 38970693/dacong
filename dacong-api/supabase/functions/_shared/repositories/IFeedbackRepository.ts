/**
 * Feedback Repository Interface
 * 反馈仓储接口 - 定义反馈数据访问的抽象
 */

import { UserFeedback } from "../domain/UserFeedback.ts";

export interface IFeedbackRepository {
  /**
   * 创建反馈
   */
  create(feedback: Omit<UserFeedback, "id" | "createdAt">): Promise<UserFeedback>;

  /**
   * 根据内容ID查找反馈
   */
  findByContentId(contentId: string, limit?: number, offset?: number): Promise<UserFeedback[]>;

  /**
   * 根据用户ID查找反馈
   */
  findByUserId(userId: string, limit?: number, offset?: number): Promise<UserFeedback[]>;

  /**
   * 检查用户是否已反馈
   */
  hasUserFeedback(contentId: string, userId: string): Promise<boolean>;

  /**
   * 检查IP是否已反馈（匿名用户）
   */
  hasIpFeedback(contentId: string, ipAddress: string): Promise<boolean>;

  /**
   * 获取内容的反馈统计
   */
  getStatsByContentId(contentId: string): Promise<{
    total: number;
    helpful: number;
    unhelpful: number;
    helpfulRate: number;
  }>;
}
