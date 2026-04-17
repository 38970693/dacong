/// CDN 配置
///
/// 管理静态资源的 CDN 加速配置
library;

/// CDN 配置类
class CdnConfig {
  /// CDN 基础 URL
  ///
  /// 可通过环境变量 CDN_URL 配置
  /// 默认值：https://cdn.dacong.ai
  static const String imageBaseUrl = String.fromEnvironment(
    'CDN_URL',
    defaultValue: 'https://cdn.dacong.ai',
  );

  /// 是否启用 CDN
  ///
  /// 可通过环境变量 ENABLE_CDN 配置
  /// 默认值：true
  static const bool enableCdn = bool.fromEnvironment(
    'ENABLE_CDN',
    defaultValue: true,
  );

  /// 回退到本地资源的基础 URL
  static const String fallbackBaseUrl = String.fromEnvironment(
    'FALLBACK_URL',
    defaultValue: 'https://dacong.ai',
  );

  /// 获取图片 URL
  ///
  /// [path] 图片路径，如 'images/logo.png'
  /// [useWebP] 是否使用 WebP 格式（需要 CDN 支持）
  /// [width] 图片宽度（用于 CDN 图片优化）
  /// [quality] 图片质量 1-100（用于 CDN 图片优化）
  ///
  /// 返回完整的图片 URL
  static String getImageUrl(
    String path, {
    bool useWebP = false,
    int? width,
    int? quality,
  }) {
    if (!enableCdn) {
      return '$fallbackBaseUrl/$path';
    }

    final buffer = StringBuffer('$imageBaseUrl/$path');

    // 添加查询参数用于 CDN 图片优化
    final params = <String>[];

    if (useWebP) {
      params.add('format=webp');
    }

    if (width != null) {
      params.add('width=$width');
    }

    if (quality != null && quality >= 1 && quality <= 100) {
      params.add('quality=$quality');
    }

    if (params.isNotEmpty) {
      buffer.write('?${params.join('&')}');
    }

    return buffer.toString();
  }

  /// 获取静态资源 URL
  ///
  /// [path] 资源路径，如 'assets/fonts/main.woff2'
  ///
  /// 返回完整的资源 URL
  static String getAssetUrl(String path) {
    if (!enableCdn) {
      return '$fallbackBaseUrl/$path';
    }
    return '$imageBaseUrl/$path';
  }

  /// 获取视频 URL
  ///
  /// [path] 视频路径
  ///
  /// 返回完整的视频 URL
  static String getVideoUrl(String path) {
    if (!enableCdn) {
      return '$fallbackBaseUrl/$path';
    }
    return '$imageBaseUrl/$path';
  }

  /// 获取字体 URL
  ///
  /// [path] 字体路径
  ///
  /// 返回完整的字体 URL
  static String getFontUrl(String path) {
    if (!enableCdn) {
      return '$fallbackBaseUrl/$path';
    }
    return '$imageBaseUrl/$path';
  }

  /// 预加载图片
  ///
  /// [paths] 图片路径列表
  ///
  /// 用于预加载关键图片资源
  static List<String> preloadImages(List<String> paths) {
    return paths.map((path) => getImageUrl(path)).toList();
  }

  /// 获取响应式图片 URL
  ///
  /// [path] 图片路径
  /// [sizes] 不同尺寸的宽度列表，如 [320, 640, 1024]
  ///
  /// 返回 srcset 字符串，用于响应式图片
  static String getResponsiveImageSrcSet(String path, List<int> sizes) {
    if (!enableCdn) {
      return '$fallbackBaseUrl/$path';
    }

    return sizes
        .map((size) => '${getImageUrl(path, width: size)} ${size}w')
        .join(', ');
  }

  /// 获取缩略图 URL
  ///
  /// [path] 原图路径
  /// [size] 缩略图尺寸（正方形）
  ///
  /// 返回缩略图 URL
  static String getThumbnailUrl(String path, int size) {
    return getImageUrl(
      path,
      width: size,
      quality: 80,
      useWebP: true,
    );
  }

  /// 获取 CDN 域名
  static String get domain {
    final uri = Uri.parse(imageBaseUrl);
    return uri.host;
  }

  /// 检查 URL 是否使用 CDN
  static bool isCdnUrl(String url) {
    return url.startsWith(imageBaseUrl);
  }

  /// 将普通 URL 转换为 CDN URL
  ///
  /// [url] 原始 URL
  ///
  /// 返回 CDN URL，如果已经是 CDN URL 则返回原值
  static String toCdnUrl(String url) {
    if (isCdnUrl(url)) {
      return url;
    }

    // 移除域名部分，只保留路径
    final uri = Uri.parse(url);
    final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;

    return getAssetUrl(path);
  }
}
