/**
 * Supabase Feedback Repository Implementation
 * Supabase反馈仓储实现
 */

import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { UserFeedback } from "../domain/UserFeedback.ts";
import { IFeedbackRepository } from "./IFeedbackRepository.ts";

export class SupabaseFeedbackRepository implements IFeedbackRepository {
  private readonly tableName = "user_feedback";

  constructor(private readonly supabase: SupabaseClient) {}

  async create(
    feedback: Omit<UserFeedback, "id" | "createdAt">
  ): Promise<UserFeedback> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .insert({
        content_id: feedback.contentId,
        user_id: feedback.userId,
        is_helpful: feedback.isHelpful,
        comment: feedback.comment,
        user_agent: feedback.userAgent,
        ip_address: feedback.ipAddress,
      })
      .select()
      .single();

    if (error) throw new Error(`Failed to create feedback: ${error.message}`);
    return UserFeedback.fromDatabase(data);
  }

  async findByContentId(
    contentId: string,
    limit = 20,
    offset = 0
  ): Promise<UserFeedback[]> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select("*")
      .eq("content_id", contentId)
      .order("created_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (error || !data) return [];
    return data.map((row) => UserFeedback.fromDatabase(row));
  }

  async findByUserId(
    userId: string,
    limit = 20,
    offset = 0
  ): Promise<UserFeedback[]> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select("*")
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (error || !data) return [];
    return data.map((row) => UserFeedback.fromDatabase(row));
  }

  async hasUserFeedback(contentId: string, userId: string): Promise<boolean> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select("id")
      .eq("content_id", contentId)
      .eq("user_id", userId)
      .single();

    return !error && data !== null;
  }

  async hasIpFeedback(contentId: string, ipAddress: string): Promise<boolean> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select("id")
      .eq("content_id", contentId)
      .eq("ip_address", ipAddress)
      .is("user_id", null)
      .single();

    return !error && data !== null;
  }

  async getStatsByContentId(contentId: string): Promise<{
    total: number;
    helpful: number;
    unhelpful: number;
    helpfulRate: number;
  }> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select("is_helpful")
      .eq("content_id", contentId);

    if (error || !data) {
      return { total: 0, helpful: 0, unhelpful: 0, helpfulRate: 0 };
    }

    const total = data.length;
    const helpful = data.filter((row) => row.is_helpful).length;
    const unhelpful = total - helpful;
    const helpfulRate = total > 0 ? helpful / total : 0;

    return { total, helpful, unhelpful, helpfulRate };
  }
}
