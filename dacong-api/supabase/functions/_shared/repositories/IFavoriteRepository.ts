/**
 * Favorite Repository Interface
 * 收藏仓储接口
 */

import { Favorite } from "../domain/Favorite.ts";

export interface IFavoriteRepository {
  /**
   * 检查用户是否已收藏内容
   */
  isFavorited(userId: string, contentId: string): Promise<boolean>;

  /**
   * 添加收藏
   */
  addFavorite(userId: string, contentId: string): Promise<Favorite>;

  /**
   * 删除收藏
   */
  removeFavorite(userId: string, contentId: string): Promise<boolean>;

  /**
   * 获取用户的收藏列表
   */
  getUserFavorites(
    userId: string,
    limit?: number,
    offset?: number
  ): Promise<Favorite[]>;

  /**
   * 获取用户收藏总数
   */
  getUserFavoritesCount(userId: string): Promise<number>;

  /**
   * 获取内容的收藏数
   */
  getContentFavoritesCount(contentId: string): Promise<number>;
}
