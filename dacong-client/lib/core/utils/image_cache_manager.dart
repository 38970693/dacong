import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 图片缓存管理器
/// 提供统一的图片加载、缓存和优化策略
class ImageCacheManager {
  ImageCacheManager._();
  static final ImageCacheManager instance = ImageCacheManager._();

  /// 配置图片缓存
  void configure() {
    // 设置图片缓存大小（100MB）
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;
    // 设置缓存图片数量（1000张）
    PaintingBinding.instance.imageCache.maximumSize = 1000;
  }

  /// 预加载图片
  Future<void> precacheImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    for (final url in imageUrls) {
      try {
        await precacheImage(
          CachedNetworkImageProvider(url),
          context,
        );
      } catch (e) {
        debugPrint('预加载图片失败: $url, 错误: $e');
      }
    }
  }

  /// 清除图片缓存
  void clearCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    final cache = PaintingBinding.instance.imageCache;
    return {
      'currentSize': cache.currentSize,
      'currentSizeBytes': cache.currentSizeBytes,
      'maximumSize': cache.maximumSize,
      'maximumSizeBytes': cache.maximumSizeBytes,
      'liveImageCount': cache.liveImageCount,
      'pendingImageCount': cache.pendingImageCount,
    };
  }
}

/// 优化的网络图片组件
class OptimizedNetworkImage extends StatelessWidget {
  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration fadeInDuration;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration,
      placeholder: (context, url) =>
          placeholder ??
          Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
      // 内存缓存配置
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      // 最大缓存宽度（避免加载过大图片）
      maxWidthDiskCache: 1200,
      maxHeightDiskCache: 1200,
    );
  }
}

/// 懒加载图片组件
class LazyLoadImage extends StatefulWidget {
  const LazyLoadImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  State<LazyLoadImage> createState() => _LazyLoadImageState();
}

class _LazyLoadImageState extends State<LazyLoadImage> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.imageUrl),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !_isVisible) {
          setState(() => _isVisible = true);
        }
      },
      child: _isVisible
          ? OptimizedNetworkImage(
              imageUrl: widget.imageUrl,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
            )
          : Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey[200],
            ),
    );
  }
}

/// 可见性检测器（简化版）
class VisibilityDetector extends StatefulWidget {
  const VisibilityDetector({
    super.key,
    required this.child,
    required this.onVisibilityChanged,
  });

  final Widget child;
  final Function(VisibilityInfo) onVisibilityChanged;

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onVisibilityChanged(VisibilityInfo(visibleFraction: 1.0));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class VisibilityInfo {
  final double visibleFraction;
  VisibilityInfo({required this.visibleFraction});
}
