import 'package:flutter/material.dart';

/// 延迟加载组件包装器
///
/// 用于实现路由级代码分割，支持懒加载页面组件
///
/// 使用示例：
/// ```dart
/// GoRoute(
///   path: '/content/:id',
///   builder: (context, state) => DeferredWidget(
///     libraryLoader: () => content_detail_deferred.loadLibrary(),
///     createWidget: () => ContentDetailPage(id: state.params['id']!),
///   ),
/// )
/// ```
class DeferredWidget extends StatefulWidget {
  /// 库加载函数
  final Future<dynamic> Function() libraryLoader;

  /// 创建组件函数
  final Widget Function() createWidget;

  /// 加载占位组件
  final Widget? placeholder;

  /// 错误组件构建器
  final Widget Function(Object error)? errorBuilder;

  const DeferredWidget({
    super.key,
    required this.libraryLoader,
    required this.createWidget,
    this.placeholder,
    this.errorBuilder,
  });

  @override
  State<DeferredWidget> createState() => _DeferredWidgetState();
}

class _DeferredWidgetState extends State<DeferredWidget> {
  Widget? _loadedWidget;
  Object? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    try {
      await widget.libraryLoader();
      if (mounted) {
        setState(() {
          _loadedWidget = widget.createWidget();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ?? _buildDefaultError();
    }

    if (_isLoading) {
      return widget.placeholder ?? _buildDefaultPlaceholder();
    }

    return _loadedWidget!;
  }

  Widget _buildDefaultPlaceholder() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
                _loadLibrary();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 延迟加载页面骨架屏
class DeferredPageSkeleton extends StatelessWidget {
  final String? title;

  const DeferredPageSkeleton({
    super.key,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title!),
            )
          : null,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '加载中...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// 预加载管理器
///
/// 用于在合适的时机预加载延迟组件
class DeferredPreloader {
  static final Map<String, Future<dynamic>> _preloadedLibraries = {};

  /// 预加载库
  static Future<void> preload(
    String key,
    Future<dynamic> Function() loader,
  ) async {
    if (_preloadedLibraries.containsKey(key)) {
      return _preloadedLibraries[key];
    }

    final future = loader();
    _preloadedLibraries[key] = future;
    return future;
  }

  /// 检查是否已预加载
  static bool isPreloaded(String key) {
    return _preloadedLibraries.containsKey(key);
  }

  /// 清除预加载缓存
  static void clear() {
    _preloadedLibraries.clear();
  }

  /// 清除指定预加载
  static void clearKey(String key) {
    _preloadedLibraries.remove(key);
  }
}
