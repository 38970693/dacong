/**
 * Share Service
 * 分享服务
 */

import { IShareRepository } from "../repositories/IShareRepository.ts";
import { Share, SharePlatform } from "../domain/Share.ts";

export class ShareService {
  constructor(private readonly shareRepository: IShareRepository) {}

  /**
   * 记录分享
   */
  async recordShare(
    contentId: string,
    platform: SharePlatform,
    userId?: string | null
  ): Promise<Share> {
    return await this.shareRepository.recordShare(contentId, platform, userId);
  }

  /**
   * 获取内容分享记录
   */
  async getContentShares(
    contentId: string,
    page = 1,
    pageSize = 20
  ): Promise<{
    shares: Share[];
    total: number;
    page: number;
    pageSize: number;
  }> {
    const offset = (page - 1) * pageSize;
    const [shares, total] = await Promise.all([
      this.shareRepository.getContentShares(contentId, pageSize, offset),
      this.shareRepository.getContentSharesCount(contentId),
    ]);

    return {
      shares,
      total,
      page,
      pageSize,
    };
  }

  /**
   * 获取用户分享记录
   */
  async getUserShares(
    userId: string,
    page = 1,
    pageSize = 20
  ): Promise<{
    shares: Share[];
    page: number;
    pageSize: number;
  }> {
    const offset = (page - 1) * pageSize;
    const shares = await this.shareRepository.getUserShares(
      userId,
      pageSize,
      offset
    );

    return {
      shares,
      page,
      pageSize,
    };
  }

  /**
   * 获取分享统计
   */
  async getShareStats(contentId: string): Promise<{
    totalShares: number;
    uniqueUsers: number;
    platformBreakdown: Record<SharePlatform, number>;
  }> {
    return await this.shareRepository.getShareStats(contentId);
  }
}
