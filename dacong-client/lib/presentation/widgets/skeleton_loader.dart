import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// 骨架屏加载器
/// 提供多种预设的骨架屏样式
class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// 内容卡片骨架屏
class ContentCardSkeleton extends StatelessWidget {
  const ContentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片占位
            const SkeletonLoader(
              width: double.infinity,
              height: 180,
              borderRadius: 8,
            ),
            const SizedBox(height: 12),
            // 标题占位
            const SkeletonLoader(
              width: double.infinity,
              height: 20,
              borderRadius: 4,
            ),
            const SizedBox(height: 8),
            // 副标题占位
            SkeletonLoader(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 16,
              borderRadius: 4,
            ),
            const SizedBox(height: 12),
            // 描述占位
            const SkeletonLoader(
              width: double.infinity,
              height: 14,
              borderRadius: 4,
            ),
            const SizedBox(height: 6),
            SkeletonLoader(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 14,
              borderRadius: 4,
            ),
            const SizedBox(height: 12),
            // 底部信息占位
            Row(
              children: [
                const SkeletonLoader(
                  width: 80,
                  height: 12,
                  borderRadius: 4,
                ),
                const SizedBox(width: 16),
                const SkeletonLoader(
                  width: 60,
                  height: 12,
                  borderRadius: 4,
                ),
                const Spacer(),
                const SkeletonLoader(
                  width: 40,
                  height: 12,
                  borderRadius: 4,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 列表项骨架屏
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // 左侧图标/头像
          const SkeletonLoader(
            width: 48,
            height: 48,
            borderRadius: 24,
          ),
          const SizedBox(width: 12),
          // 右侧内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(
                  width: double.infinity,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 14,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 网格项骨架屏
class GridItemSkeleton extends StatelessWidget {
  const GridItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片占位
          const Expanded(
            child: SkeletonLoader(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 8,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: 6),
                SkeletonLoader(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: 12,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 详情页骨架屏
class DetailPageSkeleton extends StatelessWidget {
  const DetailPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 大图占位
          const SkeletonLoader(
            width: double.infinity,
            height: 240,
            borderRadius: 12,
          ),
          const SizedBox(height: 16),
          // 标题占位
          const SkeletonLoader(
            width: double.infinity,
            height: 24,
            borderRadius: 4,
          ),
          const SizedBox(height: 12),
          // 元信息占位
          Row(
            children: [
              const SkeletonLoader(
                width: 100,
                height: 14,
                borderRadius: 4,
              ),
              const SizedBox(width: 16),
              const SkeletonLoader(
                width: 80,
                height: 14,
                borderRadius: 4,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 内容段落占位
          ...List.generate(
            5,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SkeletonLoader(
                width: index == 4
                    ? MediaQuery.of(context).size.width * 0.7
                    : double.infinity,
                height: 14,
                borderRadius: 4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 标签占位
          Row(
            children: List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SkeletonLoader(
                  width: 60 + (index * 10.0),
                  height: 28,
                  borderRadius: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 骨架屏列表
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext, int)? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder ?? (context, index) => const ListItemSkeleton(),
    );
  }
}

/// 骨架屏网格
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
  });

  final int itemCount;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const GridItemSkeleton(),
    );
  }
}
