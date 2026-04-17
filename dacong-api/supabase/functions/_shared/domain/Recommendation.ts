/**
 * Recommendation Domain Entity
 * 推荐领域实体 - 代表场景推荐配置
 */

export class Recommendation {
  constructor(
    public readonly id: string,
    public readonly scenario: string,
    public readonly rank: number,
    public readonly contentId: string,
    public readonly active: boolean,
    public readonly createdAt: Date,
    public readonly updatedAt: Date
  ) {}

  /**
   * 是否为最佳推荐
   */
  isBest(): boolean {
    return this.rank === 1;
  }

  /**
   * 是否为平替推荐
   */
  isAlternative(): boolean {
    return this.rank === 2;
  }

  /**
   * 是否为免费推荐
   */
  isFree(): boolean {
    return this.rank === 3;
  }

  /**
   * 激活推荐
   */
  activate(): Recommendation {
    return new Recommendation(
      this.id,
      this.scenario,
      this.rank,
      this.contentId,
      true,
      this.createdAt,
      new Date()
    );
  }

  /**
   * 停用推荐
   */
  deactivate(): Recommendation {
    return new Recommendation(
      this.id,
      this.scenario,
      this.rank,
      this.contentId,
      false,
      this.createdAt,
      new Date()
    );
  }

  /**
   * 转换为JSON对象
   */
  toJSON(): Record<string, unknown> {
    return {
      id: this.id,
      scenario: this.scenario,
      rank: this.rank,
      content_id: this.contentId,
      active: this.active,
      created_at: this.createdAt.toISOString(),
      updated_at: this.updatedAt.toISOString(),
    };
  }

  /**
   * 从数据库记录创建实体
   */
  static fromDatabase(row: Record<string, unknown>): Recommendation {
    return new Recommendation(
      row.id as string,
      row.scenario as string,
      row.rank as number,
      row.content_id as string,
      row.active as boolean,
      new Date(row.created_at as string),
      new Date(row.updated_at as string)
    );
  }
}
