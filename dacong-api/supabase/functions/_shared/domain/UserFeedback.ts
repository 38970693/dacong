/**
 * UserFeedback Domain Entity
 * 用户反馈领域实体
 */

export class UserFeedback {
  constructor(
    public readonly id: string,
    public readonly contentId: string,
    public readonly userId: string | null,
    public readonly isHelpful: boolean,
    public readonly comment: string | null,
    public readonly userAgent: string | null,
    public readonly ipAddress: string | null,
    public readonly createdAt: Date
  ) {}

  /**
   * 是否为正面反馈
   */
  isPositive(): boolean {
    return this.isHelpful;
  }

  /**
   * 是否为负面反馈
   */
  isNegative(): boolean {
    return !this.isHelpful;
  }

  /**
   * 是否为匿名反馈
   */
  isAnonymous(): boolean {
    return this.userId === null;
  }

  /**
   * 是否有评论
   */
  hasComment(): boolean {
    return this.comment !== null && this.comment.trim().length > 0;
  }

  /**
   * 转换为JSON对象
   */
  toJSON(): Record<string, unknown> {
    return {
      id: this.id,
      content_id: this.contentId,
      user_id: this.userId,
      is_helpful: this.isHelpful,
      comment: this.comment,
      user_agent: this.userAgent,
      ip_address: this.ipAddress,
      created_at: this.createdAt.toISOString(),
    };
  }

  /**
   * 从数据库记录创建实体
   */
  static fromDatabase(row: Record<string, unknown>): UserFeedback {
    return new UserFeedback(
      row.id as string,
      row.content_id as string,
      row.user_id as string | null,
      row.is_helpful as boolean,
      row.comment as string | null,
      row.user_agent as string | null,
      row.ip_address as string | null,
      new Date(row.created_at as string)
    );
  }

  /**
   * 创建新的反馈实体
   */
  static create(
    contentId: string,
    isHelpful: boolean,
    userId: string | null = null,
    comment: string | null = null,
    userAgent: string | null = null,
    ipAddress: string | null = null
  ): Omit<UserFeedback, "id" | "createdAt"> {
    return {
      contentId,
      userId,
      isHelpful,
      comment,
      userAgent,
      ipAddress,
    } as Omit<UserFeedback, "id" | "createdAt">;
  }
}
