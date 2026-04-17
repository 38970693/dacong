import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_admin/services/admin_api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AdminApiService', () {
    late AdminApiService apiService;

    setUpAll(() async {
      // 初始化 Supabase（测试环境）
      await Supabase.initialize(
        url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://localhost:54321'),
        anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'test-key'),
      );
    });

    setUp(() {
      apiService = AdminApiService();
    });

    group('Content Management', () {
      test('getContentList should return paginated results', () async {
        // 注意：这需要有效的认证 token
        // 在实际测试中，应该先登录获取 token
        try {
          final result = await apiService.getContentList(
            status: 'pending',
            page: 1,
            limit: 10,
          );

          expect(result, isA<Map<String, dynamic>>());
          expect(result.containsKey('items'), true);
          expect(result.containsKey('total'), true);
          expect(result.containsKey('page'), true);
        } catch (e) {
          // 如果没有认证，应该抛出异常
          expect(e.toString(), contains('Not authenticated'));
        }
      });

      test('moderateContent should require valid action', () async {
        expect(
          () => apiService.moderateContent(
            action: 'invalid_action',
            contentIds: ['test-id'],
          ),
          throwsException,
        );
      });

      test('editContent should require contentId', () async {
        expect(
          () => apiService.editContent(
            contentId: '',
            title: 'New Title',
          ),
          throwsException,
        );
      });
    });

    group('User Management', () {
      test('getUserList should return paginated results', () async {
        try {
          final result = await apiService.getUserList(
            page: 1,
            limit: 10,
          );

          expect(result, isA<Map<String, dynamic>>());
          expect(result.containsKey('items'), true);
          expect(result.containsKey('total'), true);
        } catch (e) {
          expect(e.toString(), contains('Not authenticated'));
        }
      });

      test('banUser should require userId', () async {
        expect(
          () => apiService.banUser(
            userId: '',
            ban: true,
          ),
          throwsException,
        );
      });
    });

    group('Comment Moderation', () {
      test('getCommentList should return paginated results', () async {
        try {
          final result = await apiService.getCommentList(
            page: 1,
            limit: 10,
            status: 'pending',
          );

          expect(result, isA<Map<String, dynamic>>());
          expect(result.containsKey('items'), true);
          expect(result.containsKey('total'), true);
        } catch (e) {
          expect(e.toString(), contains('Not authenticated'));
        }
      });

      test('moderateComment should require valid action', () async {
        expect(
          () => apiService.moderateComment(
            action: 'invalid_action',
            commentIds: ['test-id'],
          ),
          throwsException,
        );
      });
    });
  });
}
