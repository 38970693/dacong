/**
 * Content Domain Entity
 * 内容领域实体 - 代表已发布的内容
 */

export class Content {
  constructor(
    public readonly id: string,
    public readonly contentType: ContentType,
    public readonly titleZh: string,
    public readonly summaryZh: string | null,
    public readonly contentZh: Record<string, unknown>,
    public readonly titleEn: string | null,
    public readonly summaryEn: string | null,
    public readonly contentEn: Record<string, unknown> | null,
    public readonly scenario: Scenario | null,
    public readonly viewCount: number,
    public readonly helpfulCount: number,
    public readonly unhelpfulCount: number,
    public readonly shareCount: number,
    public readonly publishedAt: Date,
    public readonly updatedAt: Date,
    public readonly createdAt: Date
  ) {}

  /**
   * 计算有用率
   */
  get helpfulRate(): number | null {
    const total = this.helpfulCount + this.unhelpfulCount;
    if (total === 0) return null;
    return this.helpfulCount / total;
  }

  /**
   * 是否为热门内容
   */
  isPopular(): boolean {
    return this.viewCount > 1000 || this.helpfulCount > 100;
  }

  /**
   * 增加浏览次数
   */
  incrementViewCount(): Content {
    return new Content(
      this.id,
      this.contentType,
      this.titleZh,
      this.summaryZh,
      this.contentZh,
      this.titleEn,
      this.summaryEn,
      this.contentEn,
      this.scenario,
      this.viewCount + 1,
      this.helpfulCount,
      this.unhelpfulCount,
      this.shareCount,
      this.publishedAt,
      this.updatedAt,
      this.createdAt
    );
  }

  /**
   * 增加分享次数
   */
  incrementShareCount(): Content {
    return new Content(
      this.id,
      this.contentType,
      this.titleZh,
      this.summaryZh,
      this.contentZh,
      this.titleEn,
      this.summaryEn,
      this.contentEn,
      this.scenario,
      this.viewCount,
      this.helpfulCount,
      this.unhelpfulCount,
      this.shareCount + 1,
      this.publishedAt,
      this.updatedAt,
      this.createdAt
    );
  }

  /**
   * 转换为JSON对象
   */
  toJSON(): Record<string, unknown> {
    return {
      id: this.id,
      content_type: this.contentType,
      title_zh: this.titleZh,
      summary_zh: this.summaryZh,
      content_zh: this.contentZh,
      title_en: this.titleEn,
      summary_en: this.summaryEn,
      content_en: this.contentEn,
      scenario: this.scenario,
      view_count: this.viewCount,
      helpful_count: this.helpfulCount,
      unhelpful_count: this.unhelpfulCount,
      share_count: this.shareCount,
      helpful_rate: this.helpfulRate,
      published_at: this.publishedAt.toISOString(),
      updated_at: this.updatedAt.toISOString(),
      created_at: this.createdAt.toISOString(),
    };
  }

  /**
   * 从数据库记录创建实体
   */
  static fromDatabase(row: Record<string, unknown>): Content {
    return new Content(
      row.id as string,
      row.content_type as ContentType,
      row.title_zh as string,
      row.summary_zh as string | null,
      row.content_zh as Record<string, unknown>,
      row.title_en as string | null,
      row.summary_en as string | null,
      row.content_en as Record<string, unknown> | null,
      row.scenario as Scenario | null,
      row.view_count as number,
      row.helpful_count as number,
      row.unhelpful_count as number,
      row.share_count as number,
      new Date(row.published_at as string),
      new Date(row.updated_at as string),
      new Date(row.created_at as string)
    );
  }
}

/**
 * 内容类型枚举
 */
export enum ContentType {
  RECOMMENDATION = "recommendation",
  GUIDE = "guide",
  COMPARISON = "comparison",
  WEEKLY = "weekly",
}

/**
 * 场景枚举
 */
export enum Scenario {
  CODING = "coding",
  VIDEO = "video",
  IMAGE = "image",
  CHAT = "chat",
  WRITING = "writing",
  DATA = "data",
}
