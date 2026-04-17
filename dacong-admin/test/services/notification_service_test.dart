import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_admin/services/notification_service.dart';

void main() {
  group('NotificationItem', () {
    test('should create from JSON correctly', () {
      final json = {
        'id': '123',
        'type': 'contentPendingReview',
        'title': 'New Content',
        'message': 'Content needs review',
        'timestamp': '2024-04-17T10:00:00Z',
        'data': {'content_id': '456'},
        'is_read': false,
      };

      final notification = NotificationItem.fromJson(json);

      expect(notification.id, '123');
      expect(notification.type, NotificationType.contentPendingReview);
      expect(notification.title, 'New Content');
      expect(notification.message, 'Content needs review');
      expect(notification.isRead, false);
      expect(notification.data?['content_id'], '456');
    });

    test('should convert to JSON correctly', () {
      final notification = NotificationItem(
        id: '123',
        type: NotificationType.userReport,
        title: 'User Report',
        message: 'User reported content',
        timestamp: DateTime.parse('2024-04-17T10:00:00Z'),
        data: {'user_id': '789'},
        isRead: true,
      );

      final json = notification.toJson();

      expect(json['id'], '123');
      expect(json['type'], 'userReport');
      expect(json['title'], 'User Report');
      expect(json['message'], 'User reported content');
      expect(json['is_read'], true);
      expect(json['data']['user_id'], '789');
    });

    test('should handle missing data field', () {
      final json = {
        'id': '123',
        'type': 'systemError',
        'title': 'Error',
        'message': 'System error occurred',
        'timestamp': '2024-04-17T10:00:00Z',
        'is_read': false,
      };

      final notification = NotificationItem.fromJson(json);

      expect(notification.data, isNull);
    });

    test('should default isRead to false', () {
      final json = {
        'id': '123',
        'type': 'commentPendingReview',
        'title': 'New Comment',
        'message': 'Comment needs review',
        'timestamp': '2024-04-17T10:00:00Z',
      };

      final notification = NotificationItem.fromJson(json);

      expect(notification.isRead, false);
    });
  });

  group('NotificationType', () {
    test('should have all expected types', () {
      expect(NotificationType.values.length, 4);
      expect(NotificationType.values, contains(NotificationType.contentPendingReview));
      expect(NotificationType.values, contains(NotificationType.userReport));
      expect(NotificationType.values, contains(NotificationType.systemError));
      expect(NotificationType.values, contains(NotificationType.commentPendingReview));
    });
  });
}
