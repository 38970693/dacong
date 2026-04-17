/**
 * Version Deprecation Utilities
 * 版本弃用通知工具函数
 */

import {
  addDeprecationHeaders,
  getVersionConfig,
  isVersionDeprecated,
} from "./versioning.ts";

/**
 * 弃用通知配置
 */
export interface DeprecationNotice {
  version: string;
  message: string;
  sunsetDate?: string;
  migrationGuideUrl?: string;
  alternativeVersion: string;
}

/**
 * 创建带有弃用警告的响应
 *
 * @param data - 响应数据
 * @param version - API 版本
 * @param status - HTTP 状态码
 * @returns Response 对象
 */
export function createVersionedResponse(
  data: unknown,
  version: string,
  status = 200
): Response {
  const headers = new Headers({
    "Content-Type": "application/json",
  });

  // 添加版本和弃用信息
  addDeprecationHeaders(headers, version);

  return new Response(JSON.stringify(data), {
    status,
    headers,
  });
}

/**
 * 获取版本弃用通知
 *
 * @param version - API 版本
 * @returns 弃用通知对象，如果未弃用则返回 null
 */
export function getDeprecationNotice(
  version: string
): DeprecationNotice | null {
  if (!isVersionDeprecated(version)) {
    return null;
  }

  const config = getVersionConfig(version);

  return {
    version,
    message: `API version ${version} is deprecated and will be sunset on ${config.sunsetDate || "TBD"}.`,
    sunsetDate: config.sunsetDate,
    migrationGuideUrl: config.migrationGuideUrl,
    alternativeVersion: "v2",
  };
}

/**
 * 在响应数据中添加弃用通知
 *
 * @param data - 原始响应数据
 * @param version - API 版本
 * @returns 包含弃用通知的响应数据
 */
export function addDeprecationNoticeToResponse(
  data: Record<string, unknown>,
  version: string
): Record<string, unknown> {
  const notice = getDeprecationNotice(version);

  if (!notice) {
    return data;
  }

  return {
    ...data,
    deprecation: {
      isDeprecated: true,
      message: notice.message,
      sunsetDate: notice.sunsetDate,
      migrationGuide: notice.migrationGuideUrl,
      alternativeVersion: notice.alternativeVersion,
    },
  };
}

/**
 * 记录版本使用情况（用于分析）
 *
 * @param version - API 版本
 * @param endpoint - API 端点
 * @param userId - 用户ID（可选）
 */
export async function logVersionUsage(
  version: string,
  endpoint: string,
  userId?: string
): Promise<void> {
  try {
    // 这里可以集成到分析系统
    // 例如：发送到 Supabase Analytics 或其他日志系统
    console.log(
      JSON.stringify({
        timestamp: new Date().toISOString(),
        version,
        endpoint,
        userId,
        deprecated: isVersionDeprecated(version),
      })
    );
  } catch (error) {
    // 静默失败，不影响主要功能
    console.error("Failed to log version usage:", error);
  }
}

/**
 * 检查版本兼容性
 *
 * @param requestedVersion - 请求的版本
 * @param minimumVersion - 最低支持版本
 * @returns 是否兼容
 */
export function isVersionCompatible(
  requestedVersion: string,
  minimumVersion: string
): boolean {
  const requested = parseInt(requestedVersion.replace("v", ""));
  const minimum = parseInt(minimumVersion.replace("v", ""));

  return requested >= minimum;
}

/**
 * 获取版本迁移建议
 *
 * @param currentVersion - 当前版本
 * @param targetVersion - 目标版本
 * @returns 迁移建议
 */
export function getMigrationSuggestion(
  currentVersion: string,
  targetVersion: string
): string {
  const current = parseInt(currentVersion.replace("v", ""));
  const target = parseInt(targetVersion.replace("v", ""));

  if (current === target) {
    return "You are already using the latest version.";
  }

  if (current > target) {
    return `Downgrading from ${currentVersion} to ${targetVersion} is not recommended.`;
  }

  const steps = target - current;
  if (steps === 1) {
    return `Migrate from ${currentVersion} to ${targetVersion}. This is a single version upgrade.`;
  }

  return `Migrate from ${currentVersion} to ${targetVersion}. This requires ${steps} version upgrades. Consider migrating incrementally.`;
}
