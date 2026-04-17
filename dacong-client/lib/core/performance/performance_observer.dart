import 'package:flutter/material.dart';
import 'performance_monitor.dart';

/// 性能观察器
/// 自动追踪路由导航的性能
class PerformanceObserver extends NavigatorObserver {
  final PerformanceMonitor _monitor = PerformanceMonitor();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    final routeName = route.settings.name ?? 'unknown';
    _monitor.startPageLoad(routeName);

    // 在下一帧结束页面加载追踪
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _monitor.endPageLoad(routeName);
    });
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);

    if (previousRoute != null) {
      final routeName = previousRoute.settings.name ?? 'unknown';
      _monitor.startPageLoad(routeName);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _monitor.endPageLoad(routeName);
      });
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    if (newRoute != null) {
      final routeName = newRoute.settings.name ?? 'unknown';
      _monitor.startPageLoad(routeName);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _monitor.endPageLoad(routeName);
      });
    }
  }
}
