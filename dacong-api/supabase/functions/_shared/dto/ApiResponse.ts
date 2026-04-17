/**
 * API Response DTO
 * 统一的API响应格式
 */

export class ApiResponse<T> {
  constructor(
    public readonly success: boolean,
    public readonly data: T | null,
    public readonly error: string | null,
    public readonly meta?: Record<string, unknown>
  ) {}

  /**
   * 创建成功响应
   */
  static ok<T>(data: T, meta?: Record<string, unknown>): ApiResponse<T> {
    return new ApiResponse(true, data, null, meta);
  }

  /**
   * 创建错误响应
   */
  static fail<T>(error: string): ApiResponse<T> {
    return new ApiResponse(false, null, error);
  }

  /**
   * 转换为JSON对象
   */
  toJSON(): Record<string, unknown> {
    return {
      success: this.success,
      data: this.data,
      error: this.error,
      meta: this.meta,
    };
  }
}
