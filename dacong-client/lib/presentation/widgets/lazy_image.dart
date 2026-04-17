import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// 懒加载图片组件
///
/// 特性：
/// - 自动缓存网络图片
/// - Shimmer 加载占位效果
/// - 错误处理
/// - 响应式图片尺寸
class LazyImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Widget? errorWidget;
  final Duration fadeInDuration;

  const LazyImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration,
      placeholder: (context, url) => _buildPlaceholder(context, isDark),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildErrorWidget(context, isDark),
      memCacheWidth: width != null ? (width! * 2).toInt() : null,
      memCacheHeight: height != null ? (height! * 2).toInt() : null,
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder(BuildContext context, bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? (isDark ? Colors.grey[800] : Colors.white),
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, bool isDark) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Icon(
        Icons.broken_image_outlined,
        size: 48,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
      ),
    );
  }
}

/// 响应式懒加载图片
///
/// 根据屏幕尺寸自动选择合适的图片尺寸
class ResponsiveLazyImage extends StatelessWidget {
  final String baseUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ResponsiveLazyImage({
    super.key,
    required this.baseUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    // 根据屏幕宽度选择图片尺寸
    String imageUrl;
    if (screenWidth * pixelRatio <= 750) {
      imageUrl = '$baseUrl?w=750'; // 小屏
    } else if (screenWidth * pixelRatio <= 1080) {
      imageUrl = '$baseUrl?w=1080'; // 中屏
    } else {
      imageUrl = '$baseUrl?w=1920'; // 大屏
    }

    return LazyImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
    );
  }
}

/// 圆形头像懒加载组件
class LazyAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Color? backgroundColor;

  const LazyAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[300],
      child: ClipOval(
        child: LazyImage(
          imageUrl: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
