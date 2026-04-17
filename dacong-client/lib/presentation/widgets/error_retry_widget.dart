import 'package:flutter/material.dart';

/// 错误重试组件
class ErrorRetryWidget extends StatelessWidget {
  const ErrorRetryWidget({
    super.key,
    required this.onRetry,
    this.message,
    this.icon,
    this.buttonText,
  });

  final VoidCallback onRetry;
  final String? message;
  final IconData? icon;
  final String? buttonText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message ?? '加载失败',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(buttonText ?? '重试'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 网络错误组件
class NetworkErrorWidget extends StatelessWidget {
  const NetworkErrorWidget({
    super.key,
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorRetryWidget(
      onRetry: onRetry,
      message: '网络连接失败\n请检查网络设置后重试',
      icon: Icons.wifi_off,
      buttonText: '重新加载',
    );
  }
}

/// 服务器错误组件
class ServerErrorWidget extends StatelessWidget {
  const ServerErrorWidget({
    super.key,
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorRetryWidget(
      onRetry: onRetry,
      message: '服务器错误\n请稍后再试',
      icon: Icons.cloud_off,
      buttonText: '重试',
    );
  }
}

/// 超时错误组件
class TimeoutErrorWidget extends StatelessWidget {
  const TimeoutErrorWidget({
    super.key,
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorRetryWidget(
      onRetry: onRetry,
      message: '请求超时\n请检查网络连接',
      icon: Icons.access_time,
      buttonText: '重试',
    );
  }
}

/// 内联错误组件（用于列表项等）
class InlineErrorWidget extends StatelessWidget {
  const InlineErrorWidget({
    super.key,
    required this.onRetry,
    this.message,
  });

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 20, color: Colors.red[400]),
          const SizedBox(width: 8),
          Text(
            message ?? '加载失败',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

/// 错误状态管理器
class ErrorStateManager {
  ErrorStateManager._();

  /// 根据错误类型返回对应的错误组件
  static Widget buildErrorWidget({
    required dynamic error,
    required VoidCallback onRetry,
  }) {
    final errorMessage = error.toString().toLowerCase();

    if (errorMessage.contains('network') ||
        errorMessage.contains('socket') ||
        errorMessage.contains('connection')) {
      return NetworkErrorWidget(onRetry: onRetry);
    }

    if (errorMessage.contains('timeout')) {
      return TimeoutErrorWidget(onRetry: onRetry);
    }

    if (errorMessage.contains('server') ||
        errorMessage.contains('500') ||
        errorMessage.contains('502') ||
        errorMessage.contains('503')) {
      return ServerErrorWidget(onRetry: onRetry);
    }

    return ErrorRetryWidget(
      onRetry: onRetry,
      message: '出错了\n${_getErrorMessage(error)}',
    );
  }

  static String _getErrorMessage(dynamic error) {
    if (error == null) return '未知错误';
    final message = error.toString();
    if (message.length > 100) {
      return '${message.substring(0, 100)}...';
    }
    return message;
  }
}

/// 带自动重试的组件包装器
class AutoRetryWrapper extends StatefulWidget {
  const AutoRetryWrapper({
    super.key,
    required this.child,
    required this.onRetry,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
  });

  final Widget child;
  final Future<void> Function() onRetry;
  final int maxRetries;
  final Duration retryDelay;

  @override
  State<AutoRetryWrapper> createState() => _AutoRetryWrapperState();
}

class _AutoRetryWrapperState extends State<AutoRetryWrapper> {
  int _retryCount = 0;
  bool _isRetrying = false;

  Future<void> _retry() async {
    if (_retryCount >= widget.maxRetries) {
      return;
    }

    setState(() {
      _isRetrying = true;
      _retryCount++;
    });

    await Future.delayed(widget.retryDelay);

    try {
      await widget.onRetry();
    } catch (e) {
      debugPrint('重试失败 ($_retryCount/${widget.maxRetries}): $e');
      if (_retryCount < widget.maxRetries) {
        _retry();
      }
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // 首次加载时自动重试
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _retry();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isRetrying) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '正在重试 ($_retryCount/${widget.maxRetries})...',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return widget.child;
  }
}
