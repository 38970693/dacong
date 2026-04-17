/**
 * Dependency Injection Container
 * 依赖注入容器 - 管理服务实例的创建和生命周期
 */

import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { IContentRepository } from "../repositories/IContentRepository.ts";
import { IRecommendationRepository } from "../repositories/IRecommendationRepository.ts";
import { IFeedbackRepository } from "../repositories/IFeedbackRepository.ts";
import { IFavoriteRepository } from "../repositories/IFavoriteRepository.ts";
import { IShareRepository } from "../repositories/IShareRepository.ts";
import { SupabaseContentRepository } from "../repositories/SupabaseContentRepository.ts";
import { SupabaseRecommendationRepository } from "../repositories/SupabaseRecommendationRepository.ts";
import { SupabaseFeedbackRepository } from "../repositories/SupabaseFeedbackRepository.ts";
import { SupabaseFavoriteRepository } from "../repositories/SupabaseFavoriteRepository.ts";
import { SupabaseShareRepository } from "../repositories/SupabaseShareRepository.ts";
import { ContentService } from "../services/ContentService.ts";
import { RecommendationService } from "../services/RecommendationService.ts";
import { FeedbackService } from "../services/FeedbackService.ts";
import { FavoriteService } from "../services/FavoriteService.ts";
import { ShareService } from "../services/ShareService.ts";
import { ICache } from "./ICache.ts";
import { RedisCache, createRedisCacheFromEnv } from "./RedisCache.ts";

/**
 * 依赖注入容器
 * 使用单例模式确保服务实例的唯一性
 */
export class Container {
  private static instance: Container;
  private services: Map<string, unknown> = new Map();
  private cache: ICache | null = null;

  private constructor(private readonly supabase: SupabaseClient) {
    this.registerCache();
    this.registerRepositories();
    this.registerServices();
  }

  /**
   * 获取容器实例
   */
  static getInstance(supabase: SupabaseClient): Container {
    if (!Container.instance) {
      Container.instance = new Container(supabase);
    }
    return Container.instance;
  }

  /**
   * 重置容器（主要用于测试）
   */
  static reset(): void {
    Container.instance = null as unknown as Container;
  }

  /**
   * 注册缓存
   */
  private registerCache(): void {
    try {
      const redisCache = createRedisCacheFromEnv();
      // 异步连接 Redis
      redisCache.connect().catch((error) => {
        console.error("[Container] Redis connection failed:", error);
      });
      this.cache = redisCache;
      this.services.set("ICache", redisCache);
      console.log("[Container] Redis cache registered");
    } catch (error) {
      console.warn("[Container] Redis not available, cache disabled:", error.message);
      this.cache = null;
    }
  }

  /**
   * 注册仓储层
   */
  private registerRepositories(): void {
    this.services.set(
      "IContentRepository",
      new SupabaseContentRepository(this.supabase)
    );
    this.services.set(
      "IRecommendationRepository",
      new SupabaseRecommendationRepository(this.supabase)
    );
    this.services.set(
      "IFeedbackRepository",
      new SupabaseFeedbackRepository(this.supabase)
    );
    this.services.set(
      "IFavoriteRepository",
      new SupabaseFavoriteRepository(this.supabase)
    );
    this.services.set(
      "IShareRepository",
      new SupabaseShareRepository(this.supabase)
    );
  }

  /**
   * 注册服务层
   */
  private registerServices(): void {
    const contentRepo = this.get<IContentRepository>("IContentRepository");
    const recommendationRepo = this.get<IRecommendationRepository>(
      "IRecommendationRepository"
    );
    const feedbackRepo = this.get<IFeedbackRepository>("IFeedbackRepository");
    const favoriteRepo = this.get<IFavoriteRepository>("IFavoriteRepository");
    const shareRepo = this.get<IShareRepository>("IShareRepository");

    this.services.set("ContentService", new ContentService(contentRepo));
    this.services.set(
      "RecommendationService",
      new RecommendationService(recommendationRepo, contentRepo)
    );
    this.services.set(
      "FeedbackService",
      new FeedbackService(feedbackRepo, contentRepo)
    );
    this.services.set("FavoriteService", new FavoriteService(favoriteRepo));
    this.services.set("ShareService", new ShareService(shareRepo));
  }

  /**
   * 获取服务实例
   */
  get<T>(serviceName: string): T {
    const service = this.services.get(serviceName);
    if (!service) {
      throw new Error(`Service ${serviceName} not found in container`);
    }
    return service as T;
  }

  /**
   * 获取内容服务
   */
  getContentService(): ContentService {
    return this.get<ContentService>("ContentService");
  }

  /**
   * 获取推荐服务
   */
  getRecommendationService(): RecommendationService {
    return this.get<RecommendationService>("RecommendationService");
  }

  /**
   * 获取反馈服务
   */
  getFeedbackService(): FeedbackService {
    return this.get<FeedbackService>("FeedbackService");
  }

  /**
   * 获取收藏服务
   */
  getFavoriteService(): FavoriteService {
    return this.get<FavoriteService>("FavoriteService");
  }

  /**
   * 获取分享服务
   */
  getShareService(): ShareService {
    return this.get<ShareService>("ShareService");
  }

  /**
   * 获取缓存实例
   */
  getCache(): ICache | null {
    return this.cache;
  }
}
