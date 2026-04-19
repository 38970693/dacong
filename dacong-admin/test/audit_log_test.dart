import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_admin/models/audit_log.dart';

void main() {
  group('AuditLog Model Tests', () {
    test('fromJson creates AuditLog correctly', () {
      final json = {
        'id': 'log-123',
        'admin_id': 'user-456',
        'action': 'moderate_content',
        'target_type': 'content',
        'ip_address': '192.168.1.1',
        'details': {'reason': 'spam'},
        'created_at': '2024-01-01T12:00:00Z',
        'profiles': {
          'username': 'admin_user',
          'avatar_url': 'https://example.com/avatar.jpg',
        },
      };

      final log = AuditLog.fromJson(json);

      expect(log.id, 'log-123');
      expect(log.userId, 'user-456');
      expect(log.username, 'admin_user');
      expect(log.avatarUrl, 'https://example.com/avatar.jpg');
      expect(log.action, 'moderate_content');
      expect(log.resource, 'content');
      expect(log.ip, '192.168.1.1');
      expect(log.details, {'reason': 'spam'});
    });

    test('actionLabel returns correct labels', () {
      final testCases = {
        'moderate_content': '审核内容',
        'edit_content': '编辑内容',
        'delete_content': '删除内容',
        'ban_user': '封禁用户',
        'unban_user': '解封用户',
        'delete_user': '删除用户',
        'moderate_comment': '审核评论',
        'delete_comment': '删除评论',
        'login': '登录',
        'logout': '登出',
        'unknown_action': 'unknown_action',
      };

      testCases.forEach((action, expectedLabel) {
        final log = AuditLog(
          id: 'test',
          userId: 'user',
          username: 'test',
          action: action,
          resource: 'test',
          createdAt: DateTime.now(),
        );
        expect(log.actionLabel, expectedLabel);
      });
    });

    test('resourceLabel returns correct labels', () {
      final testCases = {
        'content': '内容',
        'user': '用户',
        'comment': '评论',
        'system': '系统',
        'unknown_resource': 'unknown_resource',
      };

      testCases.forEach((resource, expectedLabel) {
        final log = AuditLog(
          id: 'test',
          userId: 'user',
          username: 'test',
          action: 'test',
          resource: resource,
          createdAt: DateTime.now(),
        );
        expect(log.resourceLabel, expectedLabel);
      });
    });
  });

  group('AuditLogFilter Tests', () {
    test('hasFilters returns false when no filters set', () {
      final filter = AuditLogFilter();
      expect(filter.hasFilters, false);
    });

    test('hasFilters returns true when any filter is set', () {
      final filter1 = AuditLogFilter(userId: 'user-123');
      expect(filter1.hasFilters, true);

      final filter2 = AuditLogFilter(action: 'login');
      expect(filter2.hasFilters, true);

      final filter3 = AuditLogFilter(startDate: DateTime.now());
      expect(filter3.hasFilters, true);
    });

    test('copyWith creates new filter with updated values', () {
      final original = AuditLogFilter(
        userId: 'user-1',
        action: 'login',
      );

      final updated = original.copyWith(
        userId: 'user-2',
        resource: 'content',
      );

      expect(updated.userId, 'user-2');
      expect(updated.action, 'login');
      expect(updated.resource, 'content');
    });

    test('copyWith preserves original when no values provided', () {
      final original = AuditLogFilter(
        userId: 'user-1',
        action: 'login',
      );

      final copy = original.copyWith();

      expect(copy.userId, original.userId);
      expect(copy.action, original.action);
    });
  });
}
