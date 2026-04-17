/**
 * Share Domain Entity
 * 分享领域实体
 */

export type SharePlatform =
  | "system"
  | "wechat"
  | "weibo"
  | "twitter"
  | "facebook"
  | "linkedin"
  | "copy_link"
  | "other";

export class Share {
  constructor(
    public readonly id: string,
    public readonly userId: string | null,
    public readonly contentId: string,
    public readonly platform: SharePlatform,
    public readonly createdAt: Date
  ) {}

  /**
   * 从数据库记录创建实体
   */
  static fromDatabase(record: {
    id: string;
    user_id: string | null;
    content_id: string;
    platform: string;
    created_at: string;
  }): Share {
    return new Share(
      record.id,
      record.user_id,
      record.content_id,
      record.platform as SharePlatform,
      new Date(record.created_at)
    );
  }

  /**
   * 转换为数据库记录
   */
  toDatabase(): {
    id: string;
    user_id: string | null;
    content_id: string;
    platform: string;
    created_at: string;
  } {
    return {
      id: this.id,
      user_id: this.userId,
      content_id: this.contentId,
      platform: this.platform,
      created_at: this.createdAt.toISOString(),
    };
  }

  /**
   * 转换为JSON响应
   */
  toJSON(): {
    id: string;
    userId: string | null;
    contentId: string;
    platform: SharePlatform;
    createdAt: string;
  } {
    return {
      id: this.id,
      userId: this.userId,
      contentId: this.contentId,
      platform: this.platform,
      createdAt: this.createdAt.toISOString(),
    };
  }
}
