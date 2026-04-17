# 前端性能优化文档

## 概述

本文档详细说明了 DaCong Client 的前端性能优化策略和实现方案。

## 优化目标

- ✅ 首屏加载时间 < 2s
- ✅ 列表滚动流畅（60fps）
- ✅ 打包体积优化
- ✅ 提升用户体验

## 1. 代码分割

### 1.1 路由级代码分割

使用 `DeferredWidget` 实现路由级懒加载：

```dart
import 'package:dacong_client/presentation/widgets/deferred_widget.dart';

// 在路由配置中使用
GoRoute(
  path: '/content/:id',
  builder: (context, state) => DeferredWidget(
    libraryLoader: () => content_detail_deferred.loadLibrary(),
    createWidget: () => ContentDetailPage(id: state.params['id']!),
    placeholder: DeferredPageSkeleton(title: '内容详情'),
  ),
)
```

### 1.2 组件级代码分割

对大型组件使用延迟加载：

```dart
// 定义延迟加载库
library content_detail_deferred;
export 'content_detail_page.dart';

// 使用时
DeferredWidget(
  libraryLoader: () => content_detail_deferred.loadLibrary(),
  createWidget: () => ContentDetailPage(),
)
```

### 1.3 预加载策略

在合适的时机预加载常用路由：

```dart
import 'package:dacong_client/presentation/widgets/deferred_widget.dart';

// 应用启动后预加载
void preloadCommonRoutes() {
  DeferredPreloader.preload(
    'content_detail',
    () => content_detail_deferred.loadLibrary(),
  );
}
```

## 2. 图片优化

### 2.1 懒加载图片

使用 `LazyImage` 组件：

```dart
import 'package:dacong_client/presentation/widgets/lazy_image.dart';

// 基础用法
LazyImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 200,
  height: 200,
  borderRadius: BorderRadius.circular(8),
)

// 响应式图片
ResponsiveLazyImage(
  baseUrl: 'https://example.com/image.jpg',
  width: double.infinity,
  height: 200,
)

// 圆形头像
LazyAvatar(
  imageUrl: 'https://example.com/avatar.jpg',
  radius: 24,
)
```

### 2.2 图片缓存策略

`LazyImage` 自动实现以下缓存策略：

- 内存缓存：使用 `CachedNetworkImage` 的内存缓存
- 磁盘缓存：自动缓存到本地存储
- 智能清理：根据 LRU 算法自动清理旧缓存

### 2.3 图片格式优化

推荐使用 WebP 格式：

- 比 JPEG 小 25-35%
- 支持透明度
- 更好的压缩率

```dart
// 服务端返回 WebP 格式
LazyImage(
  imageUrl: 'https://example.com/image.webp',
)
```

### 2.4 响应式图片

根据屏幕尺寸加载不同大小的图片：

```dart
ResponsiveLazyImage(
  baseUrl: 'https://example.com/image.jpg',
  // 自动根据屏幕宽度选择：
  // - 小屏: ?w=750
  // - 中屏: ?w=1080
  // - 大屏: ?w=1920
)
```

## 3. 虚拟滚动

### 3.1 长列表优化

使用 `VirtualScrollView` 优化长列表性能：

```dart
import 'package:dacong_client/presentation/widgets/virtual_scroll_view.dart';

// 固定高度列表
VirtualScrollView(
  itemCount: 1000,
  itemExtent: 80, // 固定高度，性能最佳
  itemBuilder: (context, index) {
    return ListTile(title: Text('Item $index'));
  },
)

// 动态高度列表
VirtualScrollView(
  itemCount: 1000,
  itemBuilder: (context, index) {
    return Card(child: Text('Item $index'));
  },
)
```

### 3.2 懒加载列表项

对复杂列表项使用懒加载：

```dart
LazyListItem(
  itemKey: 'item_$index',
  builder: () => ComplexWidget(),
  placeholder: ShimmerPlaceholder(),
  visibilityThreshold: 0.1, // 10% 可见时开始加载
)
```

### 3.3 分页加载

使用 `PaginatedListView` 实现分页：

```dart
PaginatedListView<Content>(
  items: contents,
  itemBuilder: (context, item, index) {
    return ContentCard(content: item);
  },
  onRefresh: () async {
    // 下拉刷新
    await loadFirstPage();
  },
  onLoadMore: () async {
    // 上拉加载更多
    await loadNextPage();
  },
  hasMore: hasMoreData,
  isLoading: isLoading,
)
```

### 3.4 网格虚拟滚动

对网格布局使用虚拟滚动：

```dart
VirtualGridView(
  itemCount: 100,
  crossAxisCount: 2,
  mainAxisSpacing: 8,
  crossAxisSpacing: 8,
  childAspectRatio: 0.75,
  itemBuilder: (context, index) {
    return GridItem(index: index);
  },
)
```

## 4. 路由优化

### 4.1 路由预加载

使用 `RoutePreloadStrategy` 预加载路由：

```dart
import 'package:dacong_client/core/routing/optimized_router.dart';

// 预加载常用路由
RoutePreloadStrategy.preloadRoute(
  'content_detail',
  () => content_detail_deferred.loadLibrary(),
);

// 检查是否已预加载
if (RoutePreloadStrategy.isPreloaded('content_detail')) {
  // 已预加载，可以快速导航
}
```

### 4.2 路由缓存

使用 `RouteCacheManager` 缓存页面：

```dart
// 缓存页面
RouteCacheManager.cachePage('home', HomePage());

// 获取缓存页面
final cachedPage = RouteCacheManager.getCachedPage('home');

// 清除缓存
RouteCacheManager.clearCache('home');
```

### 4.3 路由过渡动画

根据设备性能选择合适的过渡动画：

```dart
// 获取推荐的过渡动画
final transition = SmartRouteLoader.getRecommendedTransition();

// 在路由中使用
pageBuilder: (context, animation, secondaryAnimation, child) {
  return transition(context, animation, secondaryAnimation, child);
}
```

### 4.4 性能监控

监控路由加载性能：

```dart
// 开始监控
RoutePerformanceMonitor.startMonitoring('content_detail');

// 结束监控
RoutePerformanceMonitor.endMonitoring('content_detail');

// 获取加载时间
final loadTime = RoutePerformanceMonitor.getLoadTime('content_detail');
print('Route loaded in ${loadTime?.inMilliseconds}ms');
```

## 5. 打包体积优化

### 5.1 分析打包体积

运行分析脚本：

```bash
cd dacong-client
./scripts/analyze_bundle_size.sh
```

脚本会生成以下报告：

- `build/analysis/size_analysis.txt` - 详细的大小分析
- `build/analysis/dependencies.txt` - 依赖树
- `build/analysis/metrics/index.html` - 代码度量报告
- `build/analysis/summary_report.txt` - 摘要报告

### 5.2 优化建议

根据分析报告执行以下优化：

1. **移除未使用的依赖**
   ```bash
   flutter pub deps --style=compact | grep unused
   ```

2. **启用代码混淆**
   ```bash
   flutter build apk --obfuscate --split-debug-info=build/debug-info
   ```

3. **分平台构建**
   ```bash
   # 只构建 ARM64
   flutter build apk --target-platform android-arm64
   ```

4. **优化资源文件**
   - 使用 WebP 格式图片
   - 压缩 JSON 配置文件
   - 移除未使用的字体

### 5.3 持续监控

在 CI/CD 中集成体积监控：

```yaml
# .gitlab-ci.yml
analyze-size:
  stage: test
  script:
    - ./scripts/analyze_bundle_size.sh
    - |
      APK_SIZE=$(du -m build/app/outputs/flutter-apk/app-release.apk | cut -f1)
      if [ "$APK_SIZE" -gt 50 ]; then
        echo "警告: APK 大小超过 50MB"
        exit 1
      fi
  artifacts:
    paths:
      - build/analysis/
```

## 6. 性能指标

### 6.1 首屏加载时间

目标：< 2s

优化措施：
- 代码分割减少初始包大小
- 预加载关键资源
- 优化启动流程

测量方法：
```dart
final startTime = DateTime.now();
// 应用启动
final loadTime = DateTime.now().difference(startTime);
print('首屏加载时间: ${loadTime.inMilliseconds}ms');
```

### 6.2 列表滚动性能

目标：60fps

优化措施：
- 使用虚拟滚动
- 固定列表项高度
- 懒加载复杂组件

测量方法：
```dart
import 'package:flutter/scheduler.dart';

SchedulerBinding.instance.addTimingsCallback((timings) {
  for (final timing in timings) {
    final fps = 1000000 / timing.totalSpan.inMicroseconds;
    print('FPS: $fps');
  }
});
```

### 6.3 内存使用

目标：< 200MB

优化措施：
- 及时释放不用的资源
- 使用图片缓存策略
- 避免内存泄漏

测量方法：
```dart
import 'dart:developer' as developer;

developer.Timeline.startSync('memory_check');
// 执行操作
developer.Timeline.finishSync();
```

## 7. 最佳实践

### 7.1 图片使用

```dart
// ✅ 好的做法
LazyImage(
  imageUrl: url,
  width: 200,
  height: 200,
  memCacheWidth: 400, // 2x 分辨率
)

// ❌ 避免
Image.network(url) // 没有缓存，没有占位符
```

### 7.2 列表渲染

```dart
// ✅ 好的做法
VirtualScrollView(
  itemCount: items.length,
  itemExtent: 80, // 固定高度
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// ❌ 避免
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
) // 一次性渲染所有项
```

### 7.3 路由导航

```dart
// ✅ 好的做法
DeferredWidget(
  libraryLoader: () => page_deferred.loadLibrary(),
  createWidget: () => PageWidget(),
)

// ❌ 避免
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => HeavyPageWidget()),
) // 同步加载大型页面
```

## 8. 性能检查清单

在发布前检查以下项目：

- [ ] 所有图片使用 LazyImage 组件
- [ ] 长列表使用虚拟滚动
- [ ] 大型页面使用代码分割
- [ ] 启用代码混淆
- [ ] 移除调试代码和日志
- [ ] 优化图片资源（WebP 格式）
- [ ] 运行打包体积分析
- [ ] 测试首屏加载时间 < 2s
- [ ] 测试列表滚动 60fps
- [ ] 检查内存使用 < 200MB

## 9. 故障排查

### 9.1 首屏加载慢

可能原因：
- 初始包太大
- 启动时执行了耗时操作
- 网络请求阻塞

解决方案：
- 使用代码分割
- 延迟非关键初始化
- 使用异步加载

### 9.2 列表滚动卡顿

可能原因：
- 列表项过于复杂
- 没有使用虚拟滚动
- 频繁的 setState

解决方案：
- 简化列表项
- 使用 VirtualScrollView
- 优化状态管理

### 9.3 内存占用高

可能原因：
- 图片缓存过多
- 内存泄漏
- 大对象未释放

解决方案：
- 配置图片缓存大小
- 检查 dispose 方法
- 使用 DevTools 分析内存

## 10. 参考资源

- [Flutter Performance Best Practices](https://flutter.dev/docs/perf/best-practices)
- [Deferred Components](https://flutter.dev/docs/perf/deferred-components)
- [Image Optimization](https://flutter.dev/docs/perf/rendering-performance)
- [List Performance](https://flutter.dev/docs/cookbook/lists/long-lists)

## 更新日志

- 2026-04-17: 初始版本，实现基础性能优化
