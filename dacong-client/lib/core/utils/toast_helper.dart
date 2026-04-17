import 'package:flutter/material.dart';

/// Toast 辅助工具
class ToastHelper {
  ToastHelper._();

  /// 显示成功提示
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showToast(
      context,
      message,
      icon: Icons.check_circle,
      backgroundColor: Colors.green[700]!,
      duration: duration,
    );
  }

  /// 显示错误提示
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showToast(
      context,
      message,
      icon: Icons.error,
      backgroundColor: Colors.red[700]!,
      duration: duration,
    );
  }

  /// 显示警告提示
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showToast(
      context,
      message,
      icon: Icons.warning,
      backgroundColor: Colors.orange[700]!,
      duration: duration,
    );
  }

  /// 显示信息提示
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showToast(
      context,
      message,
      icon: Icons.info,
      backgroundColor: Colors.blue[700]!,
      duration: duration,
    );
  }

  /// 显示普通提示
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 显示带图标的 Toast
  static void _showToast(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 显示加载提示
  static void showLoading(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(days: 1), // 长时间显示
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 隐藏当前 Toast
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// 显示带操作按钮的 Toast
  static void showWithAction(
    BuildContext context,
    String message, {
    required String actionLabel,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: actionLabel,
          onPressed: onAction,
        ),
      ),
    );
  }
}

/// 自定义 Toast 组件（覆盖层实现）
class CustomToast {
  static OverlayEntry? _overlayEntry;

  /// 显示自定义 Toast
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    ToastPosition position = ToastPosition.bottom,
    Color? backgroundColor,
    Color? textColor,
  }) {
    // 移除之前的 Toast
    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        position: position,
        backgroundColor: backgroundColor,
        textColor: textColor,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // 自动移除
    Future.delayed(duration, () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  /// 隐藏 Toast
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

/// Toast 位置
enum ToastPosition {
  top,
  center,
  bottom,
}

/// Toast 组件
class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    required this.position,
    this.backgroundColor,
    this.textColor,
  });

  final String message;
  final ToastPosition position;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alignment = switch (widget.position) {
      ToastPosition.top => Alignment.topCenter,
      ToastPosition.center => Alignment.center,
      ToastPosition.bottom => Alignment.bottomCenter,
    };

    final margin = switch (widget.position) {
      ToastPosition.top => const EdgeInsets.only(top: 80),
      ToastPosition.center => EdgeInsets.zero,
      ToastPosition.bottom => const EdgeInsets.only(bottom: 80),
    };

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Align(
        alignment: alignment,
        child: Container(
          margin: margin,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.black87,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Text(
              widget.message,
              style: TextStyle(
                color: widget.textColor ?? Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
