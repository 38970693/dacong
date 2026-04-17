import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// 日志级别
enum LogLevel {
  debug('DEBUG'),
  info('INFO'),
  warn('WARN'),
  error('ERROR');

  const LogLevel(this.value);
  final String value;
}

/// 日志上下文
typedef LogContext = Map<String, dynamic>;

/// 日志条目
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String service;
  final String screen;
  final String message;
  final LogContext? context;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.service,
    required this.screen,
    required this.message,
    this.context,
    this.error,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'timestamp': timestamp.toUtc().toIso8601String(),
      'level': level.value,
      'service': service,
      'screen': screen,
      'message': message,
    };

    if (context != null && context!.isNotEmpty) {
      json['context'] = context;
    }

    if (error != null) {
      json['error'] = {
        'type': error.runtimeType.toString(),
        'message': error.toString(),
        if (stackTrace != null) 'stack_trace': stackTrace.toString(),
      };
    }

    return json;
  }

  String toJsonString() => jsonEncode(toJson());
}

/// 结构化日志记录器
class AppLogger {
  final String service;
  final String screen;

  AppLogger({
    this.service = 'dacong-client',
    required this.screen,
  });

  void _log(LogLevel level, String message, {LogContext? context, Object? error, StackTrace? stackTrace}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      service: service,
      screen: screen,
      message: message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );

    final logString = entry.toJsonString();

    // 在开发模式下输出到控制台
    if (kDebugMode) {
      developer.log(
        logString,
        name: service,
        level: _getLevelValue(level),
        error: error,
        stackTrace: stackTrace,
      );
    }

    // TODO: 在生产环境中，可以将日志发送到远程服务器
    // 例如通过 HTTP 发送到日志收集服务
  }

  int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warn:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }

  /// 记录 DEBUG 级别日志
  void debug(String message, {LogContext? context}) {
    _log(LogLevel.debug, message, context: context);
  }

  /// 记录 INFO 级别日志
  void info(String message, {LogContext? context}) {
    _log(LogLevel.info, message, context: context);
  }

  /// 记录 WARN 级别日志
  void warn(String message, {LogContext? context}) {
    _log(LogLevel.warn, message, context: context);
  }

  /// 记录 ERROR 级别日志
  void error(String message, {Object? error, StackTrace? stackTrace, LogContext? context}) {
    _log(LogLevel.error, message, context: context, error: error, stackTrace: stackTrace);
  }

  /// 记录性能日志
  void logPerformance(String operation, int durationMs, {LogContext? context}) {
    final perfContext = {
      ...?context,
      'duration_ms': durationMs,
      'operation': operation,
    };
    info('Performance: $operation', context: perfContext);
  }

  /// 记录页面访问
  void logPageView(String pageName, {LogContext? context}) {
    final pageContext = {
      ...?context,
      'page_name': pageName,
    };
    info('Page view: $pageName', context: pageContext);
  }

  /// 记录用户操作
  void logUserAction(String action, {LogContext? context}) {
    final actionContext = {
      ...?context,
      'action': action,
    };
    info('User action: $action', context: actionContext);
  }

  /// 记录 API 请求
  void logApiRequest(String method, String path, {LogContext? context}) {
    final requestContext = {
      ...?context,
      'method': method,
      'path': path,
    };
    info('API request: $method $path', context: requestContext);
  }

  /// 记录 API 响应
  void logApiResponse(String method, String path, int statusCode, int durationMs, {LogContext? context}) {
    final responseContext = {
      ...?context,
      'method': method,
      'path': path,
      'status_code': statusCode,
      'duration_ms': durationMs,
    };

    final level = statusCode >= 500 ? LogLevel.error :
                  statusCode >= 400 ? LogLevel.warn :
                  LogLevel.info;

    _log(level, 'API response: $method $path $statusCode', context: responseContext);
  }
}

/// 创建日志实例的工厂函数
AppLogger createLogger(String screen) {
  return AppLogger(screen: screen);
}
