/**
 * Favorite Domain Entity
 * 收藏领域实体
 */

export class Favorite {
  constructor(
    public readonly id: string,
    public readonly userId: string,
    public readonly contentId: string,
    public readonly createdAt: Date
  ) {}

  /**
   * 从数据库记录创建实体
   */
  static fromDatabase(record: {
    id: string;
    user_id: string;
    content_id: string;
    created_at: string;
  }): Favorite {
    return new Favorite(
      record.id,
      record.user_id,
      record.content_id,
      new Date(record.created_at)
    );
  }

  /**
   * 转换为数据库记录
   */
  toDatabase(): {
    id: string;
    user_id: string;
    content_id: string;
    created_at: string;
  } {
    return {
      id: this.id,
      user_id: this.userId,
      content_id: this.contentId,
      created_at: this.createdAt.toISOString(),
    };
  }

  /**
   * 转换为JSON响应
   */
  toJSON(): {
    id: string;
    userId: string;
    contentId: string;
    createdAt: string;
  } {
    return {
      id: this.id,
      userId: this.userId,
      contentId: this.contentId,
      createdAt: this.createdAt.toISOString(),
    };
  }
}
