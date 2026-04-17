/**
 * Supabase Favorite Repository Implementation
 * Supabase收藏仓储实现
 */

import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { Favorite } from "../domain/Favorite.ts";
import { IFavoriteRepository } from "./IFavoriteRepository.ts";

export class SupabaseFavoriteRepository implements IFavoriteRepository {
  constructor(private readonly supabase: SupabaseClient) {}

  async isFavorited(userId: string, contentId: string): Promise<boolean> {
    const { data, error } = await this.supabase
      .from("favorites")
      .select("id")
      .eq("user_id", userId)
      .eq("content_id", contentId)
      .single();

    if (error && error.code !== "PGRST116") {
      throw new Error(`Failed to check favorite: ${error.message}`);
    }

    return !!data;
  }

  async addFavorite(userId: string, contentId: string): Promise<Favorite> {
    const { data, error } = await this.supabase
      .from("favorites")
      .insert({
        user_id: userId,
        content_id: contentId,
      })
      .select()
      .single();

    if (error) {
      throw new Error(`Failed to add favorite: ${error.message}`);
    }

    return Favorite.fromDatabase(data);
  }

  async removeFavorite(userId: string, contentId: string): Promise<boolean> {
    const { error } = await this.supabase
      .from("favorites")
      .delete()
      .eq("user_id", userId)
      .eq("content_id", contentId);

    if (error) {
      throw new Error(`Failed to remove favorite: ${error.message}`);
    }

    return true;
  }

  async getUserFavorites(
    userId: string,
    limit = 20,
    offset = 0
  ): Promise<Favorite[]> {
    const { data, error } = await this.supabase
      .from("favorites")
      .select("*")
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      throw new Error(`Failed to get user favorites: ${error.message}`);
    }

    return (data || []).map((record) => Favorite.fromDatabase(record));
  }

  async getUserFavoritesCount(userId: string): Promise<number> {
    const { count, error } = await this.supabase
      .from("favorites")
      .select("*", { count: "exact", head: true })
      .eq("user_id", userId);

    if (error) {
      throw new Error(`Failed to get user favorites count: ${error.message}`);
    }

    return count || 0;
  }

  async getContentFavoritesCount(contentId: string): Promise<number> {
    const { count, error } = await this.supabase
      .from("favorites")
      .select("*", { count: "exact", head: true })
      .eq("content_id", contentId);

    if (error) {
      throw new Error(
        `Failed to get content favorites count: ${error.message}`
      );
    }

    return count || 0;
  }
}
