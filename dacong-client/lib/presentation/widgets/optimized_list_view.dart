import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 优化的列表视图
/// 支持下拉刷新、上拉加载、虚拟滚动
class OptimizedListView<T> extends StatefulWidget {
  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onRefresh,
    this.onLoadMore,
    this.isLoading = false,
    this.hasMore = true,
    this.emptyWidget,
    this.errorWidget,
    this.loadingWidget,
    this.separatorBuilder,
    this.padding,
    this.physics,
  });

  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoadMore;
  final bool isLoading;
  final bool hasMore;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final Widget Function(BuildContext, int)? separatorBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  State<OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<OptimizedListView<T>> {
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

    // 距离底部 200px 时触发加载
    if (maxScroll - currentScroll <= 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (widget.onLoadMore == null) return;

    setState(() => _isLoadingMore = true);
    try {
      await widget.onLoadMore!();
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 空状态
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ?? _buildEmptyWidget();
    }

    // 加载状态
    if (widget.items.isEmpty && widget.isLoading) {
      return widget.loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    // 列表内容
    Widget listView = ListView.separated(
      controller: _scrollController,
      padding: widget.padding ?? const EdgeInsets.all(16),
      physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      separatorBuilder: widget.separatorBuilder ?? (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        // 加载更多指示器
        if (index >= widget.items.length) {
          return _buildLoadMoreIndicator();
        }

        // 列表项
        return widget.itemBuilder(context, widget.items[index], index);
      },
    );

    // 下拉刷新
    if (widget.onRefresh != null) {
      listView = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: listView,
      );
    }

    return listView;
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暂无数据',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (!widget.hasMore) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            '没有更多了',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// 优化的网格视图
class OptimizedGridView<T> extends StatefulWidget {
  const OptimizedGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.onRefresh,
    this.onLoadMore,
    this.isLoading = false,
    this.hasMore = true,
    this.emptyWidget,
    this.padding,
  });

  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoadMore;
  final bool isLoading;
  final bool hasMore;
  final Widget? emptyWidget;
  final EdgeInsetsGeometry? padding;

  @override
  State<OptimizedGridView<T>> createState() => _OptimizedGridViewState<T>();
}

class _OptimizedGridViewState<T> extends State<OptimizedGridView<T>> {
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

    if (maxScroll - currentScroll <= 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (widget.onLoadMore == null) return;

    setState(() => _isLoadingMore = true);
    try {
      await widget.onLoadMore!();
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ?? _buildEmptyWidget();
    }

    if (widget.items.isEmpty && widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget gridView = GridView.builder(
      controller: _scrollController,
      padding: widget.padding ?? const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        childAspectRatio: widget.childAspectRatio,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
      ),
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          return _buildLoadMoreIndicator();
        }
        return widget.itemBuilder(context, widget.items[index], index);
      },
    );

    if (widget.onRefresh != null) {
      gridView = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: gridView,
      );
    }

    return gridView;
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暂无数据',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (_isLoadingMore) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    return const SizedBox.shrink();
  }
}

/// 智能列表视图（自动检测滚动方向并优化渲染）
class SmartListView extends StatefulWidget {
  const SmartListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onRefresh,
    this.padding,
  });

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry? padding;

  @override
  State<SmartListView> createState() => _SmartListViewState();
}

class _SmartListViewState extends State<SmartListView> {
  final ScrollController _scrollController = ScrollController();
  ScrollDirection _scrollDirection = ScrollDirection.idle;

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
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.forward && _scrollDirection != ScrollDirection.forward) {
      setState(() => _scrollDirection = ScrollDirection.forward);
    } else if (direction == ScrollDirection.reverse && _scrollDirection != ScrollDirection.reverse) {
      setState(() => _scrollDirection = ScrollDirection.reverse);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget listView = ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: widget.itemCount,
      // 根据滚动方向优化缓存
      cacheExtent: _scrollDirection == ScrollDirection.reverse ? 500 : 250,
      itemBuilder: widget.itemBuilder,
    );

    if (widget.onRefresh != null) {
      listView = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: listView,
      );
    }

    return listView;
  }
}
