import 'package:flutter/material.dart';

class VirtualScrollView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double itemHeight;
  final ScrollController? controller;

  const VirtualScrollView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.itemHeight,
    this.controller,
  });

  @override
  State<VirtualScrollView> createState() => _VirtualScrollViewState();
}

class _VirtualScrollViewState extends State<VirtualScrollView> {
  late ScrollController _scrollController;
  int _firstVisibleIndex = 0;
  int _lastVisibleIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateVisibleRange();
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    _calculateVisibleRange();
  }

  void _calculateVisibleRange() {
    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;

    final firstIndex = (scrollOffset / widget.itemHeight).floor();
    final lastIndex = ((scrollOffset + viewportHeight) / widget.itemHeight).ceil();

    setState(() {
      _firstVisibleIndex = (firstIndex - 5).clamp(0, widget.itemCount);
      _lastVisibleIndex = (lastIndex + 5).clamp(0, widget.itemCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.itemCount,
      itemExtent: widget.itemHeight,
      itemBuilder: (context, index) {
        // 只渲染可见范围内的项
        if (index < _firstVisibleIndex || index >= _lastVisibleIndex) {
          return SizedBox(height: widget.itemHeight);
        }
        return widget.itemBuilder(context, index);
      },
    );
  }
}

class LazyImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const LazyImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage> {
  bool _isInView = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.imageUrl),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0 && !_isInView) {
          setState(() {
            _isInView = true;
          });
        }
      },
      child: _isInView
          ? Image.network(
              widget.imageUrl,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return widget.placeholder ??
                    Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
              },
              errorBuilder: (context, error, stackTrace) {
                return widget.errorWidget ??
                    const Icon(Icons.error, color: Colors.red);
              },
            )
          : widget.placeholder ??
              Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey.shade200,
              ),
    );
  }
}

class VisibilityDetector extends StatefulWidget {
  final Key key;
  final Widget child;
  final Function(VisibilityInfo) onVisibilityChanged;

  const VisibilityDetector({
    required this.key,
    required this.child,
    required this.onVisibilityChanged,
  }) : super(key: key);

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    final renderObject = context.findRenderObject() as RenderBox?;
    if (renderObject == null) return;

    final position = renderObject.localToGlobal(Offset.zero);
    final size = renderObject.size;
    final screenHeight = MediaQuery.of(context).size.height;

    final visibleHeight = size.height -
        (position.dy < 0 ? -position.dy : 0) -
        (position.dy + size.height > screenHeight
            ? position.dy + size.height - screenHeight
            : 0);

    final visibleFraction = visibleHeight / size.height;

    widget.onVisibilityChanged(VisibilityInfo(
      key: widget.key!,
      size: size,
      visibleFraction: visibleFraction.clamp(0.0, 1.0),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class VisibilityInfo {
  final Key key;
  final Size size;
  final double visibleFraction;

  VisibilityInfo({
    required this.key,
    required this.size,
    required this.visibleFraction,
  });
}
