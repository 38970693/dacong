import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_admin/models/dashboard_stats.dart';

void main() {
  group('DashboardStats', () {
    test('should create from JSON correctly', () {
      final json = {
        'today_dau': 100,
        'today_pv': 500,
        'today_uv': 300,
        'new_users': 20,
        'published_content': 50,
        'total_users': 1000,
        'total_content': 200,
        'pending_review': 10,
        'total_comments': 150,
        'pending_comments': 5,
        'dau_change': 10.5,
        'pv_change': 15.2,
        'uv_change': 8.3,
        'new_users_change': -2.1,
      };

      final stats = DashboardStats.fromJson(json);

      expect(stats.todayDau, 100);
      expect(stats.todayPv, 500);
      expect(stats.todayUv, 300);
      expect(stats.newUsers, 20);
      expect(stats.publishedContent, 50);
      expect(stats.totalUsers, 1000);
      expect(stats.totalContent, 200);
      expect(stats.pendingReview, 10);
      expect(stats.totalComments, 150);
      expect(stats.pendingComments, 5);
      expect(stats.dauChange, 10.5);
      expect(stats.pvChange, 15.2);
      expect(stats.uvChange, 8.3);
      expect(stats.newUsersChange, -2.1);
    });

    test('should handle missing values with defaults', () {
      final json = <String, dynamic>{};
      final stats = DashboardStats.fromJson(json);

      expect(stats.todayDau, 0);
      expect(stats.todayPv, 0);
      expect(stats.todayUv, 0);
      expect(stats.newUsers, 0);
      expect(stats.dauChange, 0.0);
    });
  });

  group('TrendData', () {
    test('should create from JSON correctly', () {
      final json = {
        'labels': ['1/1', '1/2', '1/3'],
        'dau_data': [100.0, 120.0, 110.0],
        'pv_data': [500.0, 550.0, 520.0],
        'uv_data': [300.0, 320.0, 310.0],
      };

      final trend = TrendData.fromJson(json);

      expect(trend.labels, ['1/1', '1/2', '1/3']);
      expect(trend.dauData, [100.0, 120.0, 110.0]);
      expect(trend.pvData, [500.0, 550.0, 520.0]);
      expect(trend.uvData, [300.0, 320.0, 310.0]);
    });

    test('should handle empty arrays', () {
      final json = {
        'labels': [],
        'dau_data': [],
        'pv_data': [],
        'uv_data': [],
      };

      final trend = TrendData.fromJson(json);

      expect(trend.labels, isEmpty);
      expect(trend.dauData, isEmpty);
      expect(trend.pvData, isEmpty);
      expect(trend.uvData, isEmpty);
    });
  });

  group('TopContent', () {
    test('should create from JSON correctly', () {
      final json = {
        'id': '123',
        'title': 'Test Content',
        'views': 1000,
        'likes': 50,
        'helpful_rate': 0.85,
      };

      final content = TopContent.fromJson(json);

      expect(content.id, '123');
      expect(content.title, 'Test Content');
      expect(content.views, 1000);
      expect(content.likes, 50);
      expect(content.helpfulRate, 0.85);
    });

    test('should handle missing values', () {
      final json = <String, dynamic>{};
      final content = TopContent.fromJson(json);

      expect(content.id, '');
      expect(content.title, '');
      expect(content.views, 0);
      expect(content.likes, 0);
      expect(content.helpfulRate, 0.0);
    });
  });

  group('SearchKeyword', () {
    test('should create from JSON correctly', () {
      final json = {
        'keyword': 'flutter',
        'count': 100,
      };

      final keyword = SearchKeyword.fromJson(json);

      expect(keyword.keyword, 'flutter');
      expect(keyword.count, 100);
    });

    test('should handle missing values', () {
      final json = <String, dynamic>{};
      final keyword = SearchKeyword.fromJson(json);

      expect(keyword.keyword, '');
      expect(keyword.count, 0);
    });
  });
}
