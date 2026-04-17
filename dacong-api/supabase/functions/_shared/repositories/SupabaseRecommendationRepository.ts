/**
 * Supabase Recommendation Repository Implementation
 * Supabase推荐仓储实现
 */

import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { Recommendation } from "../domain/Recommendation.ts";
import { IRecommendationRepository } from "./IRecommendationRepository.ts";

export class SupabaseRecommendationRepository
  implements IRecommendationRepository {
  private readonly tableName = "scenario_recommendations";

  constructor(private readonly supabase: SupabaseClient) {}

  async findByScenario(scenario: string): Promise<Recommendation[]> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select("*")
      .eq("scenario", scenario)
      .eq("active", true)
      .order("rank", { ascending: true });

    if (error || !data) return [];
    return data.map((row) => Recommendation.fromDatabase(row));
  }

  async findById(id: string): Promise<Recommendation | null> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select("*")
      .eq("id", id)
      .single();

    if (error || !data) return null;
    return Recommendation.fromDatabase(data);
  }

  async create(
    recommendation: Omit<Recommendation, "id" | "createdAt" | "updatedAt">
  ): Promise<Recommendation> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .insert({
        scenario: recommendation.scenario,
        rank: recommendation.rank,
        content_id: recommendation.contentId,
        active: recommendation.active,
      })
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to create recommendation: ${error.message}`);
    }
    return Recommendation.fromDatabase(data);
  }

  async update(
    id: string,
    data: Partial<Recommendation>
  ): Promise<Recommendation> {
    const updateData: Record<string, unknown> = {};
    if (data.scenario !== undefined) updateData.scenario = data.scenario;
    if (data.rank !== undefined) updateData.rank = data.rank;
    if (data.contentId !== undefined) updateData.content_id = data.contentId;
    if (data.active !== undefined) updateData.active = data.active;

    const { data: result, error } = await this.supabase
      .from(this.tableName)
      .update(updateData)
      .eq("id", id)
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to update recommendation: ${error.message}`);
    }
    return Recommendation.fromDatabase(result);
  }

  async delete(id: string): Promise<void> {
    const { error } = await this.supabase
      .from(this.tableName)
      .delete()
      .eq("id", id);

    if (error) {
      throw new Error(`Failed to delete recommendation: ${error.message}`);
    }
  }

  async findAllActive(): Promise<Recommendation[]> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select("*")
      .eq("active", true)
      .order("scenario", { ascending: true })
      .order("rank", { ascending: true });

    if (error || !data) return [];
    return data.map((row) => Recommendation.fromDatabase(row));
  }
}
