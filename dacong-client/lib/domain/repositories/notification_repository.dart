/// 通知仓储接口
abstract class NotificationRepository {
  /// 获取通知列表
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int pageSize = 20,
    bool unreadOnly = false,
  });

  /// 标记通知为已读
  Future<void> markAsRead(String notificationId);

  /// 标记所有通知为已读
  Future<void> markAllAsRead();

  /// 获取未读通知数量
  Future<int> getUnreadCount();
}
