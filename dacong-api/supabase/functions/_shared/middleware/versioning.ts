/**
 * API Version Management Middleware
 * API 版本管理中间件
 *
 * 支持从 URL 路径或 Header 中获取 API 版本
 */

export interface VersionConfig {
  version: string;
  isDeprecated: boolean;
  sunsetDate?: string;
  migrationGuideUrl?: string;
}

/**
 * 版本配置映射
 */
const VERSION_CONFIG: Record<string, VersionConfig> = {
  v1: {
    version: "v1",
    isDeprecated: false,
  },
  v2: {
    version: "v2",
    isDeprecated: false,
  },
};

/**
 * 默认版本
 */
const DEFAULT_VERSION = "v1";

/**
 * 支持的版本列表
 */
export const SUPPORTED_VERSIONS = Object.keys(VERSION_CONFIG);

/**
 * 从请求中提取 API 版本
 * 优先级：URL 路径 > Header > 默认版本
 *
 * @param req - HTTP 请求对象
 * @returns API 版本字符串（如 "v1", "v2"）
 */
export function versionMiddleware(req: Request): string {
  const url = new URL(req.url);

  // 1. 尝试从 URL 路径获取版本 (e.g., /v1/recommend, /v2/search)
  const pathVersion = url.pathname.match(/^\/v(\d+)\//)?.[1];
  if (pathVersion) {
    const version = `v${pathVersion}`;
    if (SUPPORTED_VERSIONS.includes(version)) {
      return version;
    }
  }

  // 2. 尝试从 Header 获取版本
  const headerVersion = req.headers.get("API-Version");
  if (headerVersion && SUPPORTED_VERSIONS.includes(headerVersion)) {
    return headerVersion;
  }

  // 3. 返回默认版本
  return DEFAULT_VERSION;
}

/**
 * 获取版本配置
 *
 * @param version - API 版本
 * @returns 版本配置对象
 */
export function getVersionConfig(version: string): VersionConfig {
  return VERSION_CONFIG[version] || VERSION_CONFIG[DEFAULT_VERSION];
}

/**
 * 检查版本是否已弃用
 *
 * @param version - API 版本
 * @returns 是否已弃用
 */
export function isVersionDeprecated(version: string): boolean {
  const config = getVersionConfig(version);
  return config.isDeprecated;
}

/**
 * 添加版本弃用警告头
 *
 * @param headers - 响应头对象
 * @param version - API 版本
 * @returns 更新后的响应头
 */
export function addDeprecationHeaders(
  headers: Headers,
  version: string
): Headers {
  const config = getVersionConfig(version);

  if (config.isDeprecated) {
    headers.set("Deprecation", "true");

    if (config.sunsetDate) {
      headers.set("Sunset", config.sunsetDate);
    }

    if (config.migrationGuideUrl) {
      headers.set(
        "Link",
        `<${config.migrationGuideUrl}>; rel="deprecation"`
      );
    }

    headers.set(
      "Warning",
      `299 - "API version ${version} is deprecated. Please migrate to the latest version."`
    );
  }

  // 始终添加当前版本信息
  headers.set("API-Version", version);

  return headers;
}

/**
 * 标记版本为已弃用
 *
 * @param version - API 版本
 * @param sunsetDate - 停用日期（ISO 8601 格式）
 * @param migrationGuideUrl - 迁移指南 URL
 */
export function deprecateVersion(
  version: string,
  sunsetDate?: string,
  migrationGuideUrl?: string
): void {
  if (VERSION_CONFIG[version]) {
    VERSION_CONFIG[version].isDeprecated = true;
    VERSION_CONFIG[version].sunsetDate = sunsetDate;
    VERSION_CONFIG[version].migrationGuideUrl = migrationGuideUrl;
  }
}

/**
 * 验证版本是否支持
 *
 * @param version - API 版本
 * @returns 是否支持该版本
 */
export function isSupportedVersion(version: string): boolean {
  return SUPPORTED_VERSIONS.includes(version);
}
