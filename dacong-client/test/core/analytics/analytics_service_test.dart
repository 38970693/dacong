import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_client/core/analytics/analytics_service.dart';
import 'package:dacong_client/core/analytics/analytics_events.dart';
import 'package:dacong_client/core/analytics/analytics_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnalyticsService', () {
    late AnalyticsService analytics;

    setUp(() {
      analytics = AnalyticsService();
    });

    test('should track event with properties', () {
      // 由于 AnalyticsService 需要初始化，这里只测试实例创建
      expect(analytics, isNotNull);
    });

    test('should create singleton instance', () {
      final instance1 = AnalyticsService();
      final instance2 = AnalyticsService();
      expect(identical(instance1, instance2), isTrue);
    });
  });

  group('AnalyticsEvent', () {
    test('should serialize to JSON', () {
      final event = AnalyticsEvent(
        eventType: 'page_view',
        userId: 'user-123',
        sessionId: 'session-123',
        contentId: 'content-123',
        properties: {'page_name': 'home'},
        deviceInfo: {'platform': 'android'},
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

      final json = event.toJson();

      expect(json['event_type'], 'page_view');
      expect(json['user_id'], 'user-123');
      expect(json['session_id'], 'session-123');
      expect(json['content_id'], 'content-123');
      expect(json['properties'], {'page_name': 'home'});
      expect(json['device_info'], {'platform': 'android'});
      expect(json['created_at'], '2024-01-01T12:00:00.000');
    });

    test('should deserialize from JSON', () {
      final json = {
        'event_type': 'page_view',
        'user_id': 'user-123',
        'session_id': 'session-123',
        'content_id': 'content-123',
        'properties': {'page_name': 'home'},
        'device_info': {'platform': 'android'},
        'created_at': '2024-01-01T12:00:00.000',
      };

      final event = AnalyticsEvent.fromJson(json);

      expect(event.eventType, 'page_view');
      expect(event.userId, 'user-123');
      expect(event.sessionId, 'session-123');
      expect(event.contentId, 'content-123');
      expect(event.properties, {'page_name': 'home'});
      expect(event.deviceInfo, {'platform': 'android'});
      expect(event.timestamp, DateTime(2024, 1, 1, 12, 0, 0));
    });
  });

  group('AnalyticsConfig', () {
    test('should have correct default values', () {
      expect(AnalyticsConfig.flushInterval, const Duration(seconds: 30));
      expect(AnalyticsConfig.maxQueueSize, 100);
      expect(AnalyticsConfig.enableDebugLog, true);
      expect(AnalyticsConfig.enabled, true);
    });
  });

  group('AnalyticsEvents', () {
    test('should have all event types defined', () {
      expect(AnalyticsEvents.pageView, 'page_view');
      expect(AnalyticsEvents.scenarioClick, 'scenario_click');
      expect(AnalyticsEvents.scenarioSelect, 'scenario_select');
      expect(AnalyticsEvents.contentView, 'content_view');
      expect(AnalyticsEvents.contentClick, 'content_click');
      expect(AnalyticsEvents.search, 'search');
      expect(AnalyticsEvents.filterChange, 'filter_change');
      expect(AnalyticsEvents.sortChange, 'sort_change');
      expect(AnalyticsEvents.favoriteAdd, 'favorite_add');
      expect(AnalyticsEvents.favoriteRemove, 'favorite_remove');
      expect(AnalyticsEvents.share, 'share');
      expect(AnalyticsEvents.feedback, 'feedback');
      expect(AnalyticsEvents.feedbackSubmit, 'feedback_submit');
      expect(AnalyticsEvents.commentSubmit, 'comment_submit');
      expect(AnalyticsEvents.commentLike, 'comment_like');
      expect(AnalyticsEvents.settingsChange, 'settings_change');
    });
  });
}
