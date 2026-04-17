import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 离线提示横幅
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isOffline = results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);

    if (isOffline != _isOffline) {
      setState(() => _isOffline = isOffline);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isOffline ? 40 : 0,
          child: _isOffline
              ? Container(
                  color: Colors.red[700],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '网络连接已断开',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}

/// 简化版离线检测器（不依赖 connectivity_plus）
class SimpleOfflineBanner extends StatefulWidget {
  const SimpleOfflineBanner({
    super.key,
    required this.child,
    this.checkInterval = const Duration(seconds: 10),
  });

  final Widget child;
  final Duration checkInterval;

  @override
  State<SimpleOfflineBanner> createState() => _SimpleOfflineBannerState();
}

class _SimpleOfflineBannerState extends State<SimpleOfflineBanner> {
  bool _isOffline = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(widget.checkInterval, (_) {
      // 这里可以通过实际的网络请求来检测
      // 暂时保持简单实现
    });
  }

  void setOfflineStatus(bool isOffline) {
    if (isOffline != _isOffline) {
      setState(() => _isOffline = isOffline);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isOffline ? 40 : 0,
          child: _isOffline
              ? Container(
                  color: Colors.red[700],
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '网络连接已断开',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}

/// 离线状态指示器（小组件）
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({
    super.key,
    required this.isOffline,
  });

  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            '离线',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// 网络状态管理器
class NetworkStatusManager {
  NetworkStatusManager._();
  static final NetworkStatusManager instance = NetworkStatusManager._();

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onStatusChanged => _controller.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  void updateStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _controller.add(isOnline);
    }
  }

  void dispose() {
    _controller.close();
  }
}
