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
    offset = 0,
    filters?: {
      scenario?: string;
      isFree?: boolean;
      availableInChina?: boolean;
    },
    sortBy: "relevance" | "rating" | "viewCount" = "relevance"
  ): Promise<Content[]> {
    // 过滤特殊字符
    const sanitizedQuery = query.trim().replace(/[^\w\s\u4e00-\u9fa5]/g, " ");

    if (sanitizedQuery.length === 0) {
      return [];
    }

    // 调用 PostgreSQL 搜索函数
    const { data, error } = await this.supabase.rpc("search_content", {
      search_query: sanitizedQuery,
      search_scenario: filters?.scenario || null,
      search_is_free: filters?.isFree ?? null,
      search_available_in_china: filters?.availableInChina ?? null,
      sort_by: sortBy,
      result_limit: limit,
      result_offset: offset,
    });

    if (error || !data) {
      console.error("Search error:", error);
      return [];
    }

    return data.map((row: any) => Content.fromDatabase(row));
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
