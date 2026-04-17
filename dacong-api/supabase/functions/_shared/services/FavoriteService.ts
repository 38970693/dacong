/**
 * Favorite Service
 * 收藏服务
 */

import { IFavoriteRepository } from "../repositories/IFavoriteRepository.ts";
import { Favorite } from "../domain/Favorite.ts";

export class FavoriteService {
  constructor(private readonly favoriteRepository: IFavoriteRepository) {}

  /**
   * 切换收藏状态
   */
  async toggleFavorite(
    userId: string,
    contentId: string
  ): Promise<{ favorited: boolean; favorite?: Favorite }> {
    const isFavorited = await this.favoriteRepository.isFavorited(
      userId,
      contentId
    );

    if (isFavorited) {
      await this.favoriteRepository.removeFavorite(userId, contentId);
      return { favorited: false };
    } else {
      const favorite = await this.favoriteRepository.addFavorite(
        userId,
        contentId
      );
      return { favorited: true, favorite };
    }
  }

  /**
   * 检查是否已收藏
   */
  async isFavorited(userId: string, contentId: string): Promise<boolean> {
    return await this.favoriteRepository.isFavorited(userId, contentId);
  }

  /**
   * 获取用户收藏列表
   */
  async getUserFavorites(
    userId: string,
    page = 1,
    pageSize = 20
  ): Promise<{
    favorites: Favorite[];
    total: number;
    page: number;
    pageSize: number;
  }> {
    const offset = (page - 1) * pageSize;
    const [favorites, total] = await Promise.all([
      this.favoriteRepository.getUserFavorites(userId, pageSize, offset),
      this.favoriteRepository.getUserFavoritesCount(userId),
    ]);

    return {
      favorites,
      total,
      page,
      pageSize,
    };
  }

  /**
   * 获取内容收藏数
   */
  async getContentFavoritesCount(contentId: string): Promise<number> {
    return await this.favoriteRepository.getContentFavoritesCount(contentId);
  }
}
