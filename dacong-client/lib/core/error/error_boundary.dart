import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/sentry_config.dart';

/// 全局错误边界组件
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();

    // 捕获 Flutter 框架错误
    FlutterError.onError = (details) {
      // 上报到 Sentry
      Sentry.captureException(
        details.exception,
        stackTrace: details.stack,
      );

      // 更新 UI 显示错误
      if (mounted) {
        setState(() {
          _errorDetails = details;
        });
      }

      // 打印到控制台
      FlutterError.presentError(details);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      return widget.errorBuilder?.call(_errorDetails!) ??
          _buildDefaultErrorWidget(context);
    }
    return widget.child;
  }

  Widget _buildDefaultErrorWidget(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 24),
                const Text(
                  '应用遇到了问题',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '我们已经记录了这个错误，将尽快修复。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorDetails = null;
                    });
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 异步错误处理器
class AsyncErrorHandler {
  static void init() {
    // 捕获异步错误
    PlatformDispatcher.instance.onError = (error, stack) {
      SentryConfig.captureException(
        error,
        stackTrace: stack,
        hint: 'Uncaught async error',
      );
      return true;
    };
  }
}

/// 错误报告工具类
class ErrorReporter {
  /// 报告网络错误
  static Future<void> reportNetworkError(
    dynamic error, {
    String? url,
    String? method,
    int? statusCode,
  }) async {
    SentryConfig.addBreadcrumb(
      message: 'Network error',
      category: 'http',
      level: SentryLevel.error,
      data: {
        'url': url,
        'method': method,
        'status_code': statusCode,
      },
    );

    await SentryConfig.captureException(
      error,
      hint: 'Network request failed',
      level: SentryLevel.error,
    );
  }

  /// 报告业务逻辑错误
  static Future<void> reportBusinessError(
    String message, {
    String? code,
    Map<String, dynamic>? extras,
  }) async {
    await SentryConfig.captureMessage(
      message,
      level: SentryLevel.warning,
      extras: {
        'error_code': code,
        ...?extras,
      },
    );
  }

  /// 报告用户操作错误
  static Future<void> reportUserActionError(
    String action,
    dynamic error, {
    Map<String, dynamic>? context,
  }) async {
    SentryConfig.addBreadcrumb(
      message: 'User action: $action',
      category: 'user',
      level: SentryLevel.info,
      data: context,
    );

    await SentryConfig.captureException(
      error,
      hint: 'User action failed: $action',
      level: SentryLevel.error,
    );
  }

  /// 报告性能问题
  static Future<void> reportPerformanceIssue(
    String operation,
    Duration duration, {
    Map<String, dynamic>? extras,
  }) async {
    if (duration.inMilliseconds > 3000) {
      await SentryConfig.captureMessage(
        'Slow operation: $operation took ${duration.inMilliseconds}ms',
        level: SentryLevel.warning,
        extras: {
          'operation': operation,
          'duration_ms': duration.inMilliseconds,
          ...?extras,
        },
      );
    }
  }
}
