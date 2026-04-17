import '../repositories/notification_repository.dart';

/// 获取通知列表用例
class GetNotifications {
  final NotificationRepository repository;

  GetNotifications(this.repository);

  Future<Map<String, dynamic>> call({
    int page = 1,
    int pageSize = 20,
    bool unreadOnly = false,
  }) {
    return repository.getNotifications(
      page: page,
      pageSize: pageSize,
      unreadOnly: unreadOnly,
    );
  }
}

/// 标记通知为已读用例
class MarkNotificationAsRead {
  final NotificationRepository repository;

  MarkNotificationAsRead(this.repository);

  Future<void> call(String notificationId) {
    return repository.markAsRead(notificationId);
  }
}

/// 标记所有通知为已读用例
class MarkAllNotificationsAsRead {
  final NotificationRepository repository;

  MarkAllNotificationsAsRead(this.repository);

  Future<void> call() {
    return repository.markAllAsRead();
  }
}

/// 获取未读通知数量用例
class GetUnreadNotificationCount {
  final NotificationRepository repository;

  GetUnreadNotificationCount(this.repository);

  Future<int> call() {
    return repository.getUnreadCount();
  }
}
