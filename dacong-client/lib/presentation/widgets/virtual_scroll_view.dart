import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// 虚拟滚动列表
///
/// 特性：
/// - 只渲染可见区域的项目
/// - 自动回收不可见项目
/// - 支持动态高度
/// - 优化大列表性能
class VirtualScrollView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double? itemExtent;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const VirtualScrollView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemExtent,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<VirtualScrollView> createState() => _VirtualScrollViewState();
}

class _VirtualScrollViewState extends State<VirtualScrollView> {
  @override
  Widget build(BuildContext context) {
    // 如果指定了固定高度，使用 ListView.builder 的优化版本
    if (widget.itemExtent != null) {
      return ListView.builder(
        controller: widget.controller,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        itemCount: widget.itemCount,
        itemExtent: widget.itemExtent,
        itemBuilder: widget.itemBuilder,
      );
    }

    // 动态高度使用 ListView.builder
    return ListView.builder(
      controller: widget.controller,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: widget.itemCount,
      itemBuilder: widget.itemBuilder,
    );
  }
}

/// 懒加载列表项
///
/// 当项目进入可见区域时才渲染内容
class LazyListItem extends StatefulWidget {
  final String itemKey;
  final Widget Function() builder;
  final Widget? placeholder;
  final double visibilityThreshold;

  const LazyListItem({
    super.key,
    required this.itemKey,
    required this.builder,
    this.placeholder,
    this.visibilityThreshold = 0.1,
  });

  @override
  State<LazyListItem> createState() => _LazyListItemState();
}

class _LazyListItemState extends State<LazyListItem> {
  bool _isVisible = false;
  Widget? _content;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.itemKey),
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= widget.visibilityThreshold && !_isVisible) {
          setState(() {
            _isVisible = true;
            _content = widget.builder();
          });
        }
      },
      child: _isVisible
          ? (_content ?? widget.builder())
          : (widget.placeholder ?? _buildDefaultPlaceholder()),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return const SizedBox(
      height: 100,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// 分页加载列表
///
/// 支持下拉刷新和上拉加载更多
class PaginatedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<void> Function() onRefresh;
  final Future<void> Function()? onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final double? itemExtent;
  final EdgeInsetsGeometry? padding;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onRefresh,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoading = false,
    this.emptyWidget,
    this.loadingWidget,
    this.itemExtent,
    this.padding,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !widget.hasMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8;

    if (currentScroll >= threshold && widget.onLoadMore != null) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await widget.onLoadMore!();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ?? _buildDefaultEmpty();
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        itemExtent: widget.itemExtent,
        itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < widget.items.length) {
            return widget.itemBuilder(context, widget.items[index], index);
          }

          // 加载更多指示器
          return widget.loadingWidget ?? _buildLoadingIndicator();
        },
      ),
    );
  }

  Widget _buildDefaultEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无数据',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// 网格虚拟滚动
class VirtualGridView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const VirtualGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.padding,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
