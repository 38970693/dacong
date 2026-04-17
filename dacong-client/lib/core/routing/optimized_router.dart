import 'package:flutter/material.dart';

/// 优化的路由配置
///
/// 提供路由级代码分割和预加载功能

/// 路由预加载策略
class RoutePreloadStrategy {
  static final Map<String, Future<dynamic>> _preloadCache = {};

  /// 预加载路由
  static Future<void> preloadRoute(
    String routeName,
    Future<dynamic> Function() loader,
  ) async {
    if (_preloadCache.containsKey(routeName)) {
      return _preloadCache[routeName];
    }

    final future = loader();
    _preloadCache[routeName] = future;
    return future;
  }

  /// 检查路由是否已预加载
  static bool isPreloaded(String routeName) {
    return _preloadCache.containsKey(routeName);
  }

  /// 清除预加载缓存
  static void clearCache() {
    _preloadCache.clear();
  }
}

/// 路由过渡动画配置
class RouteTransitions {
  /// 淡入淡出
  static Widget fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// 滑动过渡
  static Widget slideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeInOut;

    final tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );

    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }

  /// 缩放过渡
  static Widget scaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }

  /// 无动画
  static Widget noTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

/// 路由性能监控
class RoutePerformanceMonitor {
  static final Map<String, DateTime> _routeStartTimes = {};
  static final Map<String, Duration> _routeLoadTimes = {};

  /// 开始监控路由加载
  static void startMonitoring(String routeName) {
    _routeStartTimes[routeName] = DateTime.now();
  }

  /// 结束监控路由加载
  static void endMonitoring(String routeName) {
    final startTime = _routeStartTimes[routeName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _routeLoadTimes[routeName] = duration;
      _routeStartTimes.remove(routeName);

      // 记录性能数据
      debugPrint('Route $routeName loaded in ${duration.inMilliseconds}ms');
    }
  }

  /// 获取路由加载时间
  static Duration? getLoadTime(String routeName) {
    return _routeLoadTimes[routeName];
  }

  /// 获取所有路由性能数据
  static Map<String, Duration> getAllLoadTimes() {
    return Map.unmodifiable(_routeLoadTimes);
  }

  /// 清除性能数据
  static void clear() {
    _routeStartTimes.clear();
    _routeLoadTimes.clear();
  }
}

/// 路由缓存管理
class RouteCacheManager {
  static final Map<String, Widget> _cachedPages = {};
  static const int _maxCacheSize = 5;

  /// 缓存页面
  static void cachePage(String routeName, Widget page) {
    if (_cachedPages.length >= _maxCacheSize) {
      // 移除最早的缓存
      final firstKey = _cachedPages.keys.first;
      _cachedPages.remove(firstKey);
    }
    _cachedPages[routeName] = page;
  }

  /// 获取缓存页面
  static Widget? getCachedPage(String routeName) {
    return _cachedPages[routeName];
  }

  /// 清除指定路由缓存
  static void clearCache(String routeName) {
    _cachedPages.remove(routeName);
  }

  /// 清除所有缓存
  static void clearAllCache() {
    _cachedPages.clear();
  }

  /// 获取缓存大小
  static int getCacheSize() {
    return _cachedPages.length;
  }
}

/// 智能路由加载器
///
/// 根据网络状况和设备性能自动调整加载策略
class SmartRouteLoader {
  static bool _isLowEndDevice = false;
  static bool _isSlowNetwork = false;

  /// 设置设备性能等级
  static void setDevicePerformance({required bool isLowEnd}) {
    _isLowEndDevice = isLowEnd;
  }

  /// 设置网络状况
  static void setNetworkSpeed({required bool isSlow}) {
    _isSlowNetwork = isSlow;
  }

  /// 是否应该预加载
  static bool shouldPreload() {
    // 低端设备或慢网络不预加载
    return !_isLowEndDevice && !_isSlowNetwork;
  }

  /// 是否应该使用缓存
  static bool shouldCache() {
    // 低端设备不缓存
    return !_isLowEndDevice;
  }

  /// 获取推荐的过渡动画
  static Widget Function(
    BuildContext,
    Animation<double>,
    Animation<double>,
    Widget,
  ) getRecommendedTransition() {
    // 低端设备使用无动画过渡
    if (_isLowEndDevice) {
      return RouteTransitions.noTransition;
    }
    return RouteTransitions.fadeTransition;
  }
}

/// 路由优化配置
class RouteOptimizationConfig {
  /// 是否启用路由预加载
  final bool enablePreload;

  /// 是否启用路由缓存
  final bool enableCache;

  /// 是否启用性能监控
  final bool enablePerformanceMonitoring;

  /// 最大缓存页面数
  final int maxCacheSize;

  /// 预加载延迟（毫秒）
  final int preloadDelay;

  const RouteOptimizationConfig({
    this.enablePreload = true,
    this.enableCache = true,
    this.enablePerformanceMonitoring = true,
    this.maxCacheSize = 5,
    this.preloadDelay = 1000,
  });

  /// 默认配置
  static const RouteOptimizationConfig defaultConfig =
      RouteOptimizationConfig();

  /// 性能优先配置
  static const RouteOptimizationConfig performanceConfig =
      RouteOptimizationConfig(
    enablePreload: true,
    enableCache: true,
    maxCacheSize: 10,
    preloadDelay: 500,
  );

  /// 低端设备配置
  static const RouteOptimizationConfig lowEndConfig = RouteOptimizationConfig(
    enablePreload: false,
    enableCache: false,
    maxCacheSize: 2,
    preloadDelay: 2000,
  );
}
