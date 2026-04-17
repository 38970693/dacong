/**
 * Share Repository Interface
 * 分享仓储接口
 */

import { Share, SharePlatform } from "../domain/Share.ts";

export interface IShareRepository {
  /**
   * 记录分享
   */
  recordShare(
    contentId: string,
    platform: SharePlatform,
    userId?: string | null
  ): Promise<Share>;

  /**
   * 获取内容的分享记录
   */
  getContentShares(
    contentId: string,
    limit?: number,
    offset?: number
  ): Promise<Share[]>;

  /**
   * 获取内容的分享总数
   */
  getContentSharesCount(contentId: string): Promise<number>;

  /**
   * 获取用户的分享记录
   */
  getUserShares(
    userId: string,
    limit?: number,
    offset?: number
  ): Promise<Share[]>;

  /**
   * 获取分享统计
   */
  getShareStats(contentId: string): Promise<{
    totalShares: number;
    uniqueUsers: number;
    platformBreakdown: Record<SharePlatform, number>;
  }>;
}
