import 'package:flutter/material.dart';

/// 收藏按钮组件
/// 用于内容详情页面，支持切换收藏状态
class FavoriteButton extends StatelessWidget {
  final String contentId;
  final bool isFavorited;
  final VoidCallback onToggle;
  final bool isLoading;

  const FavoriteButton({
    super.key,
    required this.contentId,
    required this.isFavorited,
    required this.onToggle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          : Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: isFavorited
                  ? Colors.red
                  : Theme.of(context).iconTheme.color,
            ),
      onPressed: isLoading ? null : onToggle,
      tooltip: isFavorited ? '取消收藏' : '收藏',
    );
  }
}

/// 收藏按钮（带动画效果）
class AnimatedFavoriteButton extends StatefulWidget {
  final String contentId;
  final bool isFavorited;
  final VoidCallback onToggle;
  final bool isLoading;

  const AnimatedFavoriteButton({
    super.key,
    required this.contentId,
    required this.isFavorited,
    required this.onToggle,
    this.isLoading = false,
  });

  @override
  State<AnimatedFavoriteButton> createState() => _AnimatedFavoriteButtonState();
}

class _AnimatedFavoriteButtonState extends State<AnimatedFavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: widget.isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : Icon(
                widget.isFavorited ? Icons.favorite : Icons.favorite_border,
                color: widget.isFavorited
                    ? Colors.red
                    : Theme.of(context).iconTheme.color,
              ),
        onPressed: widget.isLoading ? null : _handleTap,
        tooltip: widget.isFavorited ? '取消收藏' : '收藏',
      ),
    );
  }
}
