/**
 * Supabase Content Repository Implementation
 * Supabase内容仓储实现
 */

import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { Content, Scenario } from "../domain/Content.ts";
import { IContentRepository } from "./IContentRepository.ts";

export class SupabaseContentRepository implements IContentRepository {
  private readonly tableName = "published_content";

  constructor(private readonly supabase: SupabaseClient) {}

  async findById(id: string): Promise<Content | null> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select("*")
      .eq("id", id)
      .single();

    if (error || !data) return null;
    return Content.fromDatabase(data);
  }

  async findByScenario(scenario: Scenario, limit = 20): Promise<Content[]> {
    const { data, error } = await this.supabase
      .from("scenario_recommendations")
      .select(`
        rank,
        published_content (*)
      `)
      .eq("scenario", scenario)
      .eq("active", true)
      .order("rank", { ascending: true })
      .limit(limit);

    if (error || !data) return [];

    return data
      .filter((row) => row.published_content)
      .map((row) => Content.fromDatabase(row.published_content));
  }

  async search(
    query: string,
    language: "zh" | "en" = "zh",
    limit = 20,
    offset = 0
  ): Promise<Content[]> {
    const titleColumn = language === "zh" ? "title_zh" : "title_en";
    const summaryColumn = language === "zh" ? "summary_zh" : "summary_en";

    const { data, error } = await this.supabase
      .from(this.tableName)
      .select("*")
      .or(`${titleColumn}.ilike.%${query}%,${summaryColumn}.ilike.%${query}%`)
      .order("published_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (error || !data) return [];
    return data.map((row) => Content.fromDatabase(row));
  }

  async findPopular(limit = 10): Promise<Content[]> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select("*")
      .order("helpful_count", { ascending: false })
      .order("view_count", { ascending: false })
      .limit(limit);

    if (error || !data) return [];
    return data.map((row) => Content.fromDatabase(row));
  }

  async findRecent(limit = 10): Promise<Content[]> {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .select("*")
      .order("published_at", { ascending: false })
      .limit(limit);

    if (error || !data) return [];
    return data.map((row) => Content.fromDatabase(row));
  }

  async incrementViewCount(id: string): Promise<void> {
    await this.supabase.rpc("increment_view_count", { content_id: id });
  }

  async incrementShareCount(id: string): Promise<void> {
    await this.supabase.rpc("increment_share_count", { content_id: id });
  }

  async count(): Promise<number> {
    const { count, error } = await this.supabase
      .from(this.tableName)
      .select("*", { count: "exact", head: true });

    if (error) return 0;
    return count || 0;
  }
}
