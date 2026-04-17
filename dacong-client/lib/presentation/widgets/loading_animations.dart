import 'package:flutter/material.dart';

/// 加载动画组件集合
class LoadingAnimations {
  LoadingAnimations._();

  /// 标准圆形加载指示器
  static Widget circular({
    double size = 40,
    Color? color,
    double strokeWidth = 4,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: color != null ? AlwaysStoppedAnimation(color) : null,
      ),
    );
  }

  /// 脉冲动画
  static Widget pulse({
    double size = 40,
    Color? color,
  }) {
    return _PulseAnimation(size: size, color: color);
  }

  /// 跳动的点
  static Widget bouncingDots({
    Color? color,
    double size = 12,
  }) {
    return _BouncingDotsAnimation(color: color, size: size);
  }

  /// 旋转的方块
  static Widget rotatingSquare({
    double size = 40,
    Color? color,
  }) {
    return _RotatingSquareAnimation(size: size, color: color);
  }

  /// 波浪动画
  static Widget wave({
    Color? color,
    double size = 40,
  }) {
    return _WaveAnimation(color: color, size: size);
  }
}

/// 脉冲动画
class _PulseAnimation extends StatefulWidget {
  const _PulseAnimation({
    required this.size,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).primaryColor;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: widget.size * 0.6,
                height: widget.size * 0.6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 跳动的点动画
class _BouncingDotsAnimation extends StatefulWidget {
  const _BouncingDotsAnimation({
    this.color,
    required this.size,
  });

  final Color? color;
  final double size;

  @override
  State<_BouncingDotsAnimation> createState() => _BouncingDotsAnimationState();
}

class _BouncingDotsAnimationState extends State<_BouncingDotsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).primaryColor;

    return SizedBox(
      width: widget.size * 4,
      height: widget.size * 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              final value = (_controller.value - delay).clamp(0.0, 1.0);
              final offset = Curves.easeInOut.transform(
                (value * 2 - 1).abs(),
              );

              return Transform.translate(
                offset: Offset(0, -widget.size * offset),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// 旋转方块动画
class _RotatingSquareAnimation extends StatefulWidget {
  const _RotatingSquareAnimation({
    required this.size,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  State<_RotatingSquareAnimation> createState() =>
      _RotatingSquareAnimationState();
}

class _RotatingSquareAnimationState extends State<_RotatingSquareAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).primaryColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(widget.size * 0.2),
            ),
          ),
        );
      },
    );
  }
}

/// 波浪动画
class _WaveAnimation extends StatefulWidget {
  const _WaveAnimation({
    this.color,
    required this.size,
  });

  final Color? color;
  final double size;

  @override
  State<_WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<_WaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).primaryColor;

    return SizedBox(
      width: widget.size * 3,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.1;
              final value = (_controller.value - delay).clamp(0.0, 1.0);
              final height = widget.size * (0.3 + 0.7 * Curves.easeInOut.transform(
                (value * 2 - 1).abs(),
              ));

              return Container(
                width: widget.size * 0.15,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(widget.size * 0.1),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// 全屏加载遮罩
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    this.message,
    this.child,
  });

  final String? message;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                child ?? LoadingAnimations.circular(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示加载遮罩
  static void show(
    BuildContext context, {
    String? message,
    Widget? child,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingOverlay(
        message: message,
        child: child,
      ),
    );
  }

  /// 隐藏加载遮罩
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}

/// 内联加载指示器
class InlineLoading extends StatelessWidget {
  const InlineLoading({
    super.key,
    this.message,
    this.size = 24,
  });

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          if (message != null) ...[
            const SizedBox(width: 12),
            Text(
              message!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}
