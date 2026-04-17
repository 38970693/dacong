# Sentry 配置说明

## 环境变量配置

在运行应用前，需要配置 Sentry DSN：

```bash
# 开发环境
flutter run --dart-define=SENTRY_DSN=your_sentry_dsn_here

# 生产环境构建
flutter build apk --dart-define=SENTRY_DSN=your_sentry_dsn_here
flutter build ios --dart-define=SENTRY_DSN=your_sentry_dsn_here
```

## 使用示例

### 1. 设置用户上下文

```dart
import 'package:dacong_client/core/config/sentry_config.dart';

// 用户登录后
SentryConfig.setUser(
  id: user.id,
  email: user.email,
  username: user.name,
  extras: {
    'subscription': user.subscriptionType,
  },
);

// 用户登出后
SentryConfig.clearUser();
```

### 2. 手动捕获异常

```dart
try {
  // 业务逻辑
} catch (e, stackTrace) {
  await SentryConfig.captureException(
    e,
    stackTrace: stackTrace,
    hint: '数据加载失败',
    level: SentryLevel.error,
  );
}
```

### 3. 添加面包屑

```dart
SentryConfig.addBreadcrumb(
  message: '用户点击了搜索按钮',
  category: 'user-action',
  level: SentryLevel.info,
  data: {'query': searchQuery},
);
```

### 4. 性能追踪

```dart
final transaction = SentryConfig.startTransaction(
  name: 'load-content',
  operation: 'http.request',
  description: '加载内容列表',
);

try {
  // 执行操作
  await loadContent();
  transaction.status = SpanStatus.ok();
} catch (e) {
  transaction.status = SpanStatus.internalError();
  rethrow;
} finally {
  await transaction.finish();
}
```

### 5. 报告网络错误

```dart
import 'package:dacong_client/core/error/error_boundary.dart';

try {
  final response = await dio.get('/api/content');
} catch (e) {
  await ErrorReporter.reportNetworkError(
    e,
    url: '/api/content',
    method: 'GET',
    statusCode: 500,
  );
}
```

## 功能特性

- ✅ 自动捕获未处理的异常
- ✅ 自动捕获 Flutter 框架错误
- ✅ 性能监控和追踪
- ✅ 用户会话追踪
- ✅ 面包屑记录
- ✅ 截图附件
- ✅ 视图层级附件
- ✅ 敏感信息过滤
- ✅ 环境标签
- ✅ 友好的错误 UI

## 注意事项

1. 生产环境请务必配置真实的 Sentry DSN
2. 采样率已针对开发和生产环境优化
3. 敏感信息（密码、token 等）会自动过滤
4. 错误边界会显示友好的错误提示
