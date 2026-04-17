import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// 性能监控器
/// 监控页面加载时间、API 请求时间、渲染性能等
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, DateTime> _pageLoadStartTimes = {};
  final Map<String, DateTime> _apiCallStartTimes = {};
  final List<double> _frameRates = [];

  bool _isMonitoring = false;
  Timer? _frameRateTimer;

  /// 初始化性能监控
  void initialize() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // 监控帧率
    _startFrameRateMonitoring();

    debugPrint('✅ Performance monitoring initialized');
  }

  /// 停止性能监控
  void dispose() {
    _isMonitoring = false;
    _frameRateTimer?.cancel();
    _pageLoadStartTimes.clear();
    _apiCallStartTimes.clear();
    _frameRates.clear();
  }

  /// 开始追踪页面加载
  void startPageLoad(String pageName) {
    _pageLoadStartTimes[pageName] = DateTime.now();
    debugPrint('📊 Page load started: $pageName');
  }

  /// 结束追踪页面加载
  void endPageLoad(String pageName) {
    final startTime = _pageLoadStartTimes.remove(pageName);
    if (startTime == null) {
      debugPrint('⚠️ No start time found for page: $pageName');
      return;
    }

    final duration = DateTime.now().difference(startTime);
    trackPageLoad(pageName, duration);
  }

  /// 记录页面加载时间
  void trackPageLoad(String pageName, Duration duration) {
    final milliseconds = duration.inMilliseconds;

    debugPrint('📊 Page loaded: $pageName in ${milliseconds}ms');

    // 上报到 Sentry
    _reportToSentry(
      'page_load',
      pageName,
      milliseconds.toDouble(),
      {
        'page_name': pageName,
        'duration_ms': milliseconds,
      },
    );

    // 如果加载时间过长，记录警告
    if (milliseconds > 3000) {
      debugPrint('🔴 CRITICAL: Slow page load detected: $pageName (${milliseconds}ms)');
      _reportSlowOperation('page_load', pageName, milliseconds);
    } else if (milliseconds > 1000) {
      debugPrint('🟡 WARNING: Slow page load detected: $pageName (${milliseconds}ms)');
    }
  }

  /// 开始追踪 API 调用
  void startApiCall(String endpoint) {
    final key = '${endpoint}_${DateTime.now().millisecondsSinceEpoch}';
    _apiCallStartTimes[key] = DateTime.now();
  }

  /// 结束追踪 API 调用
  void endApiCall(String endpoint, {bool success = true}) {
    // 找到最近的开始时间
    final keys = _apiCallStartTimes.keys.where((k) => k.startsWith(endpoint)).toList();
    if (keys.isEmpty) {
      debugPrint('⚠️ No start time found for API call: $endpoint');
      return;
    }

    final key = keys.last;
    final startTime = _apiCallStartTimes.remove(key);
    if (startTime == null) return;

    final duration = DateTime.now().difference(startTime);
    trackApiCall(endpoint, duration, success: success);
  }

  /// 记录 API 请求时间
  void trackApiCall(String endpoint, Duration duration, {bool success = true}) {
    final milliseconds = duration.inMilliseconds;

    debugPrint('📊 API call: $endpoint in ${milliseconds}ms (${success ? 'success' : 'failed'})');

    // 上报到 Sentry
    _reportToSentry(
      'api_call',
      endpoint,
      milliseconds.toDouble(),
      {
        'endpoint': endpoint,
        'duration_ms': milliseconds,
        'success': success,
      },
    );

    // 如果请求时间过长，记录警告
    if (milliseconds > 5000) {
      debugPrint('🔴 CRITICAL: Slow API call detected: $endpoint (${milliseconds}ms)');
      _reportSlowOperation('api_call', endpoint, milliseconds);
    } else if (milliseconds > 2000) {
      debugPrint('🟡 WARNING: Slow API call detected: $endpoint (${milliseconds}ms)');
    }
  }

  /// 监控帧率
  void _startFrameRateMonitoring() {
    if (!kReleaseMode) {
      // 仅在 debug 模式下监控帧率
      _frameRateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        final fps = _calculateAverageFps();
        if (fps < 30) {
          debugPrint('🔴 CRITICAL: Low frame rate detected: ${fps.toStringAsFixed(1)} FPS');
        } else if (fps < 50) {
          debugPrint('🟡 WARNING: Low frame rate detected: ${fps.toStringAsFixed(1)} FPS');
        }
        _frameRates.clear();
      });
    }
  }

  /// 记录帧率
  void trackFrameRate(double fps) {
    _frameRates.add(fps);

    // 如果帧率过低，立即报告
    if (fps < 30) {
      _reportToSentry(
        'frame_rate',
        'low_fps',
        fps,
        {
          'fps': fps,
          'threshold': 30,
        },
      );
    }
  }

  /// 计算平均帧率
  double _calculateAverageFps() {
    if (_frameRates.isEmpty) return 60.0;
    return _frameRates.reduce((a, b) => a + b) / _frameRates.length;
  }

  /// 上报到 Sentry
  void _reportToSentry(
    String operation,
    String description,
    double value,
    Map<String, dynamic> tags,
  ) {
    try {
      // 创建事务
      final transaction = Sentry.startTransaction(
        operation,
        'performance',
        bindToScope: false,
      );

      // 设置性能测量
      transaction.setMeasurement(operation, value);

      // 设置标签
      for (final entry in tags.entries) {
        transaction.setTag(entry.key, entry.value.toString());
      }

      transaction.finish();
    } catch (e) {
      debugPrint('⚠️ Failed to report to Sentry: $e');
    }
  }

  /// 报告慢操作
  void _reportSlowOperation(String type, String name, int durationMs) {
    try {
      Sentry.captureMessage(
        'Slow $type detected: $name',
        level: SentryLevel.warning,
        withScope: (scope) {
          scope.setTag('performance_issue', 'slow_operation');
          scope.setTag('operation_type', type);
          scope.setTag('operation_name', name);
          scope.setExtra('duration_ms', durationMs);
        },
      );
    } catch (e) {
      debugPrint('⚠️ Failed to report slow operation: $e');
    }
  }

  /// 获取性能统计
  Map<String, dynamic> getStats() {
    return {
      'average_fps': _calculateAverageFps(),
      'active_page_loads': _pageLoadStartTimes.length,
      'active_api_calls': _apiCallStartTimes.length,
      'is_monitoring': _isMonitoring,
    };
  }
}

/// 性能监控扩展
extension PerformanceMonitorExtension on PerformanceMonitor {
  /// 追踪异步操作
  Future<T> trackAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final startTime = DateTime.now();
    try {
      final result = await operation();
      final duration = DateTime.now().difference(startTime);
      debugPrint('📊 Async operation: $operationName completed in ${duration.inMilliseconds}ms');
      return result;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('❌ Async operation: $operationName failed after ${duration.inMilliseconds}ms');
      rethrow;
    }
  }
}
