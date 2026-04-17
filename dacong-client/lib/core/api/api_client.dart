/// API 版本管理客户端
///
/// 支持多版本 API 调用和自动版本检测
library;

import 'dart:developer' as developer;

/// API 版本配置
class ApiVersionConfig {
  final String version;
  final bool isDeprecated;
  final DateTime? sunsetDate;
  final String? migrationGuideUrl;

  const ApiVersionConfig({
    required this.version,
    this.isDeprecated = false,
    this.sunsetDate,
    this.migrationGuideUrl,
  });
}

/// API 客户端
///
/// 注意：此文件为示例代码，实际项目中需要：
/// 1. 添加 http 依赖到 pubspec.yaml
/// 2. 或使用项目现有的 HTTP 客户端（如 dio）
class ApiClient {
  final String baseUrl;
  final String apiVersion;

  ApiClient({
    required this.baseUrl,
    this.apiVersion = 'v1',
  });

  /// 构建端点 URL
  String getEndpoint(String path) {
    // 移除路径开头的斜杠（如果有）
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$baseUrl/$apiVersion/$cleanPath';
  }

  /// GET 请求示例
  ///
  /// 实际项目中需要使用具体的 HTTP 客户端实现
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse(getEndpoint(path));
    final finalUri = queryParameters != null
        ? uri.replace(queryParameters: queryParameters)
        : uri;

    // 这里需要替换为实际的 HTTP 客户端调用
    // 例如使用 dio 或 http 包
    throw UnimplementedError(
      'Please implement HTTP client. URL: $finalUri, Headers: $headers',
    );
  }

  /// POST 请求示例
  ///
  /// 实际项目中需要使用具体的 HTTP 客户端实现
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse(getEndpoint(path));

    // 这里需要替换为实际的 HTTP 客户端调用
    throw UnimplementedError(
      'Please implement HTTP client. URL: $uri, Body: $body',
    );
  }

  /// 检查弃用警告
  void checkDeprecationWarnings(Map<String, String> responseHeaders) {
    final deprecation = responseHeaders['deprecation'];
    if (deprecation == 'true') {
      final sunsetDate = responseHeaders['sunset'];
      final link = responseHeaders['link'];
      final warning = responseHeaders['warning'];

      developer.log(
        'API Version Deprecation Warning',
        name: 'ApiClient',
        error: {
          'version': apiVersion,
          'sunsetDate': sunsetDate,
          'migrationGuide': link,
          'warning': warning,
        },
      );
    }
  }
}

/// API 版本管理器
class ApiVersionManager {
  static const String currentVersion = 'v1';
  static const String latestVersion = 'v2';

  /// 检测最优版本
  ///
  /// 尝试使用最新版本，如果不可用则回退到当前版本
  static Future<String> detectOptimalVersion(String baseUrl) async {
    try {
      // 这里需要实现实际的 HTTP 请求
      // 例如使用 dio 或 http 包检查健康端点
      final healthUrl = '$baseUrl/$latestVersion/health';

      // 临时返回当前版本
      developer.log(
        'Version detection not implemented. Check: $healthUrl',
        name: 'ApiVersionManager',
      );

      return currentVersion;
    } catch (e) {
      developer.log(
        'Latest version not available, falling back to $currentVersion',
        name: 'ApiVersionManager',
        error: e,
      );
    }

    return currentVersion;
  }

  /// 判断是否应该升级
  static bool shouldUpgrade(String currentVersion, String latestVersion) {
    final current = int.tryParse(currentVersion.replaceAll('v', '')) ?? 1;
    final latest = int.tryParse(latestVersion.replaceAll('v', '')) ?? 1;
    return latest > current;
  }

  /// 比较版本
  static int compareVersions(String version1, String version2) {
    final v1 = int.tryParse(version1.replaceAll('v', '')) ?? 1;
    final v2 = int.tryParse(version2.replaceAll('v', '')) ?? 1;
    return v1.compareTo(v2);
  }
}

/// API 响应包装器
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final Map<String, dynamic>? meta;
  final ApiVersionConfig? versionInfo;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.meta,
    this.versionInfo,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      error: json['error'] as String?,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return {
      'success': success,
      if (data != null) 'data': toJsonT(data as T),
      if (error != null) 'error': error,
      if (meta != null) 'meta': meta,
    };
  }
}

/// 使用示例
///
/// ```dart
/// // 创建客户端
/// final client = ApiClient(
///   baseUrl: 'https://api.dacong.ai',
///   apiVersion: 'v1',
/// );
///
/// // 发起请求
/// final response = await client.get(
///   'get-recommendations',
///   queryParameters: {
///     'scenario': 'morning',
///     'language': 'zh',
///   },
/// );
///
/// // 解析响应
/// if (response.statusCode == 200) {
///   final data = jsonDecode(response.body);
///   print(data);
/// }
///
/// // 关闭客户端
/// client.close();
/// ```
