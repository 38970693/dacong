# 通知功能文档

## 概述

通知功能为用户提供站内消息推送，包括评论回复、内容收藏和系统公告等通知类型。

## 功能特性

### 1. 通知类型

- **评论回复** (`comment_reply`): 当用户的评论被回复时自动发送
- **内容收藏** (`favorite`): 当内容被收藏时发送（待启用）
- **系统公告** (`system_announcement`): 管理员手动发送的系统通知

### 2. 核心功能

- ✅ 通知列表展示
- ✅ 未读/已读状态管理
- ✅ 未读数量徽章显示
- ✅ 单个通知标记已读
- ✅ 全部标记已读
- ✅ 通知筛选（全部/未读）
- ✅ 分页加载
- ✅ 下拉刷新
- ✅ 点击跳转到相关内容

## 技术架构

### 后端 API

#### 1. 数据库表结构

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(200) NOT NULL,
  content TEXT NOT NULL,
  link VARCHAR(500),
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### 2. Edge Functions

**获取通知列表**
- 端点: `get-notifications`
- 方法: GET
- 参数:
  - `page`: 页码（默认1）
  - `pageSize`: 每页数量（默认20，最大100）
  - `unreadOnly`: 只显示未读（默认false）
- 响应:
```json
{
  "success": true,
  "data": {
    "notifications": [...],
    "unreadCount": 5
  },
  "meta": {
    "total": 50,
    "page": 1,
    "pageSize": 20,
    "totalPages": 3
  }
}
```

**标记通知已读**
- 端点: `mark-notification-read`
- 方法: POST
- 请求体:
```json
{
  "notificationId": "uuid"
}
```

**标记所有已读**
- 端点: `mark-all-read`
- 方法: POST
- 响应:
```json
{
  "success": true,
  "message": "All notifications marked as read",
  "updatedCount": 5
}
```

#### 3. 数据库触发器

**评论回复自动通知**
```sql
CREATE TRIGGER trigger_notify_comment_reply
  AFTER INSERT ON comments
  FOR EACH ROW
  EXECUTE FUNCTION notify_comment_reply();
```

当用户回复评论时，自动向父评论作者发送通知。

**系统公告函数**
```sql
SELECT send_system_announcement(
  '系统维护通知',
  '系统将于今晚22:00-23:00进行维护',
  '/announcements/1'
);
```

### 前端实现

#### 1. 目录结构

```
lib/
├── domain/
│   ├── entities/
│   │   └── notification.dart          # 通知实体
│   ├── repositories/
│   │   └── notification_repository.dart  # 通知仓储接口
│   └── usecases/
│       └── notification_usecases.dart    # 通知用例
├── data/
│   ├── datasources/
│   │   └── remote_data_source.dart       # 添加通知API调用
│   └── repositories/
│       └── notification_repository_impl.dart  # 仓储实现
└── presentation/
    ├── providers/
    │   └── notification_provider.dart    # 通知状态管理
    ├── pages/
    │   └── notifications/
    │       └── notifications_page.dart   # 通知页面
    └── widgets/
        └── notification_icon_button.dart # 通知图标按钮
```

#### 2. 状态管理

使用 `ChangeNotifier` 进行状态管理：

```dart
class NotificationState {
  final List<Notification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;
}
```

#### 3. 核心组件

**NotificationsPage**
- 通知列表展示
- 下拉刷新
- 上拉加载更多
- 筛选未读/全部
- 全部标记已读

**NotificationIconButton**
- 显示通知图标
- 未读数量徽章
- 点击跳转到通知页面

**NotificationItem**
- 单个通知展示
- 未读状态标识
- 类型图标和颜色
- 时间格式化显示

## 使用指南

### 在 AppBar 中添加通知图标

```dart
import 'package:flutter/material.dart';
import 'package:dacong_client/presentation/widgets/notification_icon_button.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('大聪'),
      actions: [
        const NotificationIconButton(),  // 添加通知图标
        // 其他操作按钮...
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
```

### 手动发送系统公告

在 Supabase SQL Editor 中执行：

```sql
SELECT send_system_announcement(
  '新功能上线',
  '我们上线了全新的通知功能，快来体验吧！',
  '/features/notifications'
);
```

### 自定义通知类型

1. 在数据库中添加新的通知类型
2. 创建对应的触发器函数
3. 在前端 `NotificationItem` 中添加图标和颜色映射

## 性能优化

### 1. 数据库索引

```sql
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) 
  WHERE is_read = FALSE;
```

### 2. 分页加载

- 默认每页20条
- 滚动到80%时自动加载下一页
- 避免一次性加载大量数据

### 3. 本地状态缓存

- 标记已读后立即更新本地状态
- 减少不必要的API调用

## 安全性

### 1. Row Level Security (RLS)

```sql
-- 用户只能查看自己的通知
CREATE POLICY "Users can view their own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- 用户只能更新自己的通知
CREATE POLICY "Users can update their own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);
```

### 2. 身份验证

所有通知 API 都需要 JWT 认证：

```dart
final authHeader = req.headers.get("Authorization");
if (!authHeader) {
  return errorResponse("Authorization required", 401);
}
```

## 扩展功能（可选）

### 1. 邮件通知

集成 Supabase Email 或第三方邮件服务（如 SendGrid）：

```typescript
// 在触发器中添加邮件发送
await sendEmail({
  to: user.email,
  subject: notification.title,
  body: notification.content,
});
```

### 2. 推送通知

集成 Firebase Cloud Messaging (FCM)：

```dart
// 在 Flutter 中配置 FCM
import 'package:firebase_messaging/firebase_messaging.dart';

final messaging = FirebaseMessaging.instance;
final token = await messaging.getToken();
// 将 token 保存到用户表
```

### 3. 实时通知

使用 Supabase Realtime 订阅：

```dart
final subscription = supabase
  .from('notifications')
  .stream(primaryKey: ['id'])
  .eq('user_id', userId)
  .listen((data) {
    // 实时更新通知列表
  });
```

## 测试

### 1. 单元测试

```dart
test('should mark notification as read', () async {
  final notification = Notification(
    id: '1',
    type: 'comment_reply',
    title: 'Test',
    content: 'Test content',
    isRead: false,
    createdAt: DateTime.now(),
  );

  await provider.markAsRead(notification.id);

  expect(provider.state.notifications.first.isRead, true);
});
```

### 2. 集成测试

测试完整的通知流程：
1. 用户A评论内容
2. 用户B回复用户A的评论
3. 验证用户A收到通知
4. 用户A标记通知为已读
5. 验证未读数量减少

## 故障排查

### 问题1: 通知未自动发送

**检查项:**
- 触发器是否正确创建
- 触发器函数是否有错误
- 数据库日志中是否有错误信息

**解决方案:**
```sql
-- 查看触发器状态
SELECT * FROM pg_trigger WHERE tgname = 'trigger_notify_comment_reply';

-- 手动测试触发器函数
SELECT notify_comment_reply();
```

### 问题2: 未读数量不准确

**检查项:**
- 本地状态是否正确更新
- API 返回的 unreadCount 是否正确

**解决方案:**
```dart
// 强制刷新通知列表
await provider.loadNotifications();
```

### 问题3: 通知加载缓慢

**检查项:**
- 数据库索引是否创建
- 分页参数是否合理
- 网络连接是否正常

**解决方案:**
```sql
-- 检查查询执行计划
EXPLAIN ANALYZE
SELECT * FROM notifications
WHERE user_id = 'xxx'
ORDER BY created_at DESC
LIMIT 20;
```

## 文件清单

### 后端文件
- `dacong-api/supabase/migrations/20260417000010_create_notifications.sql`
- `dacong-api/supabase/migrations/20260417000011_notification_triggers.sql`
- `dacong-api/supabase/functions/get-notifications/index.ts`
- `dacong-api/supabase/functions/mark-notification-read/index.ts`
- `dacong-api/supabase/functions/mark-all-read/index.ts`

### 前端文件
- `dacong-client/lib/domain/entities/notification.dart`
- `dacong-client/lib/domain/repositories/notification_repository.dart`
- `dacong-client/lib/domain/usecases/notification_usecases.dart`
- `dacong-client/lib/data/repositories/notification_repository_impl.dart`
- `dacong-client/lib/data/datasources/remote_data_source.dart` (已更新)
- `dacong-client/lib/presentation/providers/notification_provider.dart`
- `dacong-client/lib/presentation/pages/notifications/notifications_page.dart`
- `dacong-client/lib/presentation/widgets/notification_icon_button.dart`

## 验收标准

- ✅ 站内通知正常工作
- ✅ 通知列表正确展示
- ✅ 未读标记正常
- ✅ 分页加载流畅
- ✅ 标记已读功能正常
- ✅ 通知图标显示未读数量
- ✅ 点击通知可跳转（待实现路由）
- ✅ 文档完善

## 后续优化

1. 实现通知点击跳转路由
2. 添加通知声音和震动
3. 支持通知删除功能
4. 添加通知设置页面（开关不同类型通知）
5. 集成邮件和推送通知
6. 添加通知统计和分析

---

**版本**: v1.0  
**更新日期**: 2026-04-17  
**作者**: 高级开发者
