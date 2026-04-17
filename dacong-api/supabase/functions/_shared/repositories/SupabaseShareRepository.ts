/**
 * Supabase Share Repository Implementation
 * Supabase分享仓储实现
 */

import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { Share, SharePlatform } from "../domain/Share.ts";
import { IShareRepository } from "./IShareRepository.ts";

export class SupabaseShareRepository implements IShareRepository {
  constructor(private readonly supabase: SupabaseClient) {}

  async recordShare(
    contentId: string,
    platform: SharePlatform,
    userId?: string | null
  ): Promise<Share> {
    const { data, error } = await this.supabase
      .from("shares")
      .insert({
        content_id: contentId,
        platform,
        user_id: userId || null,
      })
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to record share: ${error.message}`);
    }

    return Share.fromDatabase(data);
  }

  async getContentShares(
    contentId: string,
    limit = 20,
    offset = 0
  ): Promise<Share[]> {
    const { data, error } = await this.supabase
      .from("shares")
      .select("*")
      .eq("content_id", contentId)
      .order("created_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      throw new Error(`Failed to get content shares: ${error.message}`);
    }

    return (data || []).map((record) => Share.fromDatabase(record));
  }

  async getContentSharesCount(contentId: string): Promise<number> {
    const { count, error } = await this.supabase
      .from("shares")
      .select("*", { count: "exact", head: true })
      .eq("content_id", contentId);

    if (error) {
      throw new Error(`Failed to get content shares count: ${error.message}`);
    }

    return count || 0;
  }

  async getUserShares(
    userId: string,
    limit = 20,
    offset = 0
  ): Promise<Share[]> {
    const { data, error } = await this.supabase
      .from("shares")
      .select("*")
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      throw new Error(`Failed to get user shares: ${error.message}`);
    }

    return (data || []).map((record) => Share.fromDatabase(record));
  }

  async getShareStats(contentId: string): Promise<{
    totalShares: number;
    uniqueUsers: number;
    platformBreakdown: Record<SharePlatform, number>;
  }> {
    const { data, error } = await this.supabase
      .from("content_share_stats")
      .select("*")
      .eq("content_id", contentId)
      .single();

    if (error && error.code !== "PGRST116") {
      throw new Error(`Failed to get share stats: ${error.message}`);
    }

    if (!data) {
      return {
        totalShares: 0,
        uniqueUsers: 0,
        platformBreakdown: {
          system: 0,
          wechat: 0,
          weibo: 0,
          twitter: 0,
          facebook: 0,
          linkedin: 0,
          copy_link: 0,
          other: 0,
        },
      };
    }

    return {
      totalShares: data.total_shares || 0,
      uniqueUsers: data.unique_users || 0,
      platformBreakdown: {
        system: data.system_shares || 0,
        wechat: data.wechat_shares || 0,
        weibo: data.weibo_shares || 0,
        twitter: data.twitter_shares || 0,
        facebook: data.facebook_shares || 0,
        linkedin: data.linkedin_shares || 0,
        copy_link: data.copy_link_shares || 0,
        other: 0,
      },
    };
  }
}
