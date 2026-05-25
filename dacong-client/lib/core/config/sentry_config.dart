import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryConfig {
  static const String _dsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  static const String _version = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.1.0',
  );

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static Future<void> init(AppRunner appRunner) async {
    if (_dsn.isEmpty) {
      if (kDebugMode) {
        debugPrint('Sentry DSN not configured, skipping initialization');
      }
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = _dsn;

        // 环境配置
        options.environment = kDebugMode ? 'development' : 'production';

        // 发布版本 (从环境变量获取，支持 CI/CD 注入)
        options.release = 'dacong-client@$_version';

        // 采样率配置
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.2;
        // ignore: experimental_member_use
        options.profilesSampleRate = kDebugMode ? 1.0 : 0.1;

        // 性能监控
        options.enableAutoPerformanceTracing = true;
        options.enableAutoSessionTracking = true;

        // 调试模式
        options.debug = kDebugMode;

        // 附件配置
        options.attachScreenshot = true;
        options.screenshotQuality = SentryScreenshotQuality.low;
        // ignore: experimental_member_use
        options.attachViewHierarchy = true;

        // 过滤敏感信息
        options.beforeSend = (event, hint) {
          // 移除敏感数据
          if (event.request?.data != null) {
            final data = event.request!.data;
            if (data is Map) {
              data.remove('password');
              data.remove('token');
              data.remove('api_key');
            }
          }
          return event;
        };

        // 面包屑过滤
        options.beforeBreadcrumb = (breadcrumb, hint) {
          // 过滤掉不重要的面包屑
          if (breadcrumb?.category == 'ui.click' &&
              breadcrumb?.message?.contains('debug') == true) {
            return null;
          }
          return breadcrumb;
        };
      },
      appRunner: appRunner,
    );
    _initialized = true;
  }

  /// 设置用户上下文
  static void setUser({
    required String id,
    String? email,
    String? username,
    Map<String, dynamic>? extras,
  }) {
    if (!_initialized) return;
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: id,
        email: email,
        username: username,
        data: extras,
      ));
    });
  }

  /// 清除用户上下文
  static void clearUser() {
    if (!_initialized) return;
    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// 设置标签
  static void setTag(String key, String value) {
    if (!_initialized) return;
    Sentry.configureScope((scope) {
      scope.setTag(key, value);
    });
  }

  /// 设置上下文
  static void setContext(String key, Map<String, dynamic> value) {
    if (!_initialized) return;
    Sentry.configureScope((scope) {
      scope.setContexts(key, value);
    });
  }

  /// 添加面包屑
  static void addBreadcrumb({
    required String message,
    String? category,
    SentryLevel? level,
    Map<String, dynamic>? data,
  }) {
    if (!_initialized) return;
    Sentry.addBreadcrumb(Breadcrumb(
      message: message,
      category: category,
      level: level ?? SentryLevel.info,
      data: data,
    ));
  }

  /// 手动捕获异常
  static Future<void> captureException(
    dynamic exception, {
    dynamic stackTrace,
    String? hint,
    SentryLevel? level,
  }) async {
    if (!_initialized) {
      debugPrint('Sentry not initialized, skipping exception capture');
      return;
    }
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: hint != null ? Hint.withMap({'hint': hint}) : null,
      withScope: (scope) {
        if (level != null) {
          scope.level = level;
        }
      },
    );
  }

  /// 手动捕获消息
  static Future<void> captureMessage(
    String message, {
    SentryLevel? level,
    Map<String, dynamic>? extras,
  }) async {
    if (!_initialized) {
      debugPrint('Sentry not initialized, skipping message capture');
      return;
    }
    await Sentry.captureMessage(
      message,
      level: level ?? SentryLevel.info,
      withScope: (scope) {
        if (extras != null) {
          extras.forEach((key, value) {
            // ignore: deprecated_member_use
            scope.setExtra(key, value);
          });
        }
      },
    );
  }

  /// 开始性能追踪
  static ISentrySpan startTransaction({
    required String name,
    required String operation,
    String? description,
  }) {
    if (!_initialized) {
      return NoOpSentrySpan();
    }
    final transaction = Sentry.startTransaction(
      name,
      operation,
      description: description,
    );
    return transaction;
  }
}

/// No-op Sentry span for when Sentry is not initialized
class NoOpSentrySpan implements ISentrySpan {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // 对于返回类型为 ISentrySpan 或 ISentryTransaction 的方法，返回 this 以支持链式调用
    final returnType = invocation.memberName.toString();
    if (returnType.contains('finish') ||
        returnType.contains('startChild') ||
        returnType.contains('span')) {
      return this;
    }
    return null;
  }
}

// Extension to make NoOpSentrySpan usage transparent
extension NoOpSentrySpanExtension on NoOpSentrySpan {
  /// Returns this instance for method chaining
  NoOpSentrySpan get self => this;
}
