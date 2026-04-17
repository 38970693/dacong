import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/remote_data_source.dart';

/// 通知仓储实现
class NotificationRepositoryImpl implements NotificationRepository {
  final RemoteDataSource datasource;

  NotificationRepositoryImpl(this.datasource);

  @override
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int pageSize = 20,
    bool unreadOnly = false,
  }) async {
    final response = await datasource.getNotifications(
      page: page,
      pageSize: pageSize,
      unreadOnly: unreadOnly,
    );

    final notifications = (response['data']['notifications'] as List)
        .map((json) => Notification.fromJson(json as Map<String, dynamic>))
        .toList();

    return {
      'notifications': notifications,
      'unreadCount': response['data']['unreadCount'] as int,
      'total': response['meta']['total'] as int,
      'page': response['meta']['page'] as int,
      'pageSize': response['meta']['pageSize'] as int,
      'totalPages': response['meta']['totalPages'] as int,
    };
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await datasource.markNotificationAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead() async {
    await datasource.markAllNotificationsAsRead();
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await datasource.getNotifications(
      page: 1,
      pageSize: 1,
      unreadOnly: false,
    );
    return response['data']['unreadCount'] as int;
  }
}
