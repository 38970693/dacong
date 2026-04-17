/// 数据分析服务
///
/// 负责收集用户行为事件并上报到服务端
///
/// 特性：
/// - 批量上报（每30秒或队列满100条）
/// - 自动重试（失败后重新加入队列）
/// - 本地缓存（防止数据丢失）
/// - 性能优化（异步处理，不阻塞UI）

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'analytics_events.dart';
import 'analytics_config.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  SupabaseClient? _supabase;
  final _eventQueue = <AnalyticsEvent>[];
  final _uuid = const Uuid();

  Timer? _flushTimer;
  String? _sessionId;
  String? _userId;
  bool _isInitialized = false;

  /// 初始化分析服务
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 初始化 Supabase 客户端
      _supabase = Supabase.instance.client;

      // 生成或恢复session_id
      _sessionId = await _getOrCreateSessionId();

      // 获取当前用户ID
      _userId = _supabase?.auth.currentUser?.id;

      // 监听用户登录状态变化
      _supabase?.auth.onAuthStateChange.listen((data) {
        _userId = data.session?.user.id;
      });

      // 启动定时上报（每30秒）
      _flushTimer = Timer.periodic(
        AnalyticsConfig.flushInterval,
        (_) => flush(),
      );

      // 从本地恢复未上报的事件
      await _restoreQueueFromLocal();

      _isInitialized = true;

      if (kDebugMode) {
        print('[Analytics] Initialized with session: $_sessionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Analytics] Init failed: $e');
      }
    }
  }

  /// 追踪事件
  void track(String eventType, {Map<String, dynamic>? properties}) {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('[Analytics] Not initialized, skipping event: $eventType');
      }
      return;
    }

    try {
      final event = AnalyticsEvent(
        eventType: eventType,
        userId: _userId,
        sessionId: _sessionId!,
        contentId: properties?['content_id'],
        properties: properties ?? {},
        deviceInfo: _getDeviceInfo(),
        timestamp: DateTime.now(),
      );

      _eventQueue.add(event);

      if (kDebugMode) {
        print('[Analytics] Tracked: $eventType (queue: ${_eventQueue.length})');
      }

      // 队列满100条立即上报
      if (_eventQueue.length >= AnalyticsConfig.maxQueueSize) {
        flush();
      }

      // 保存到本地（防止丢失）
      _saveQueueToLocal();
    } catch (e) {
      if (kDebugMode) {
        print('[Analytics] Track failed: $e');
      }
    }
  }

  /// 上报事件到服务端
  Future<void> flush() async {
    if (_eventQueue.isEmpty) return;

    final events = List<AnalyticsEvent>.from(_eventQueue);
    _eventQueue.clear();

    try {
      if (kDebugMode) {
        print('[Analytics] Flushing ${events.length} events...');
      }

      // 如果 Supabase 未初始化，跳过上报
      if (_supabase == null) {
        if (kDebugMode) {
          print('[Analytics] Supabase not initialized, skipping flush');
        }
        return;
      }

      // 调用Edge Function上报事件
      await _supabase?.functions.invoke(
        'track-event',
        body: {
          'events': events.map((e) => e.toJson()).toList(),
        },
      );

      if (kDebugMode) {
        print('[Analytics] Flush success');
      }

      // 清除本地缓存
      await _clearLocalQueue();
    } catch (e) {
      // 失败重新加入队列
      _eventQueue.addAll(events);

      if (kDebugMode) {
        print('[Analytics] Flush failed: $e');
      }

      // 保存到本地
      await _saveQueueToLocal();
    }
  }

  // ========================================================================
  // 便捷方法
  // ========================================================================

  /// 追踪页面浏览
  void trackPageView(String pageName, {String? referrer}) {
    track(AnalyticsEvents.pageView, properties: {
      'page_name': pageName,
      'referrer': referrer,
    });
  }

  /// 追踪场景点击
  void trackScenarioClick(String scenarioId, String scenarioName) {
    track(AnalyticsEvents.scenarioClick, properties: {
      'scenario_id': scenarioId,
      'scenario_name': scenarioName,
    });
  }

  /// 追踪内容查看
  void trackContentView(
    String contentId,
    String contentType, {
    String? scenario,
    String? referrer,
  }) {
    track(AnalyticsEvents.contentView, properties: {
      'content_id': contentId,
      'content_type': contentType,
      'scenario': scenario,
      'referrer': referrer,
    });
  }

  /// 追踪搜索
  void trackSearch(String query, int resultCount) {
    track(AnalyticsEvents.search, properties: {
      'query': query,
      'result_count': resultCount,
    });
  }

  /// 追踪收藏
  void trackFavorite(String contentId, bool isAdd) {
    track(
      isAdd ? AnalyticsEvents.favoriteAdd : AnalyticsEvents.favoriteRemove,
      properties: {'content_id': contentId},
    );
  }

  /// 追踪分享
  void trackShare(String contentId, String platform) {
    track(AnalyticsEvents.share, properties: {
      'content_id': contentId,
      'platform': platform,
    });
  }

  /// 追踪反馈
  void trackFeedback(String contentId, bool isHelpful) {
    track(AnalyticsEvents.feedback, properties: {
      'content_id': contentId,
      'is_helpful': isHelpful,
    });
  }

  /// 追踪筛选变化
  void trackFilterChange(Map<String, dynamic> filters) {
    track(AnalyticsEvents.filterChange, properties: {
      'filters': filters,
    });
  }

  /// 追踪排序变化
  void trackSortChange(String sortBy, String sortOrder) {
    track(AnalyticsEvents.sortChange, properties: {
      'sort_by': sortBy,
      'sort_order': sortOrder,
    });
  }

  /// 追踪评论提交
  void trackCommentSubmit(String contentId, int commentLength) {
    track(AnalyticsEvents.commentSubmit, properties: {
      'content_id': contentId,
      'comment_length': commentLength,
    });
  }

  /// 追踪评论点赞
  void trackCommentLike(String commentId, bool isLike) {
    track(AnalyticsEvents.commentLike, properties: {
      'comment_id': commentId,
      'is_like': isLike,
    });
  }

  /// 追踪设置变化
  void trackSettingsChange(String settingKey, dynamic value) {
    track(AnalyticsEvents.settingsChange, properties: {
      'setting_key': settingKey,
      'value': value,
    });
  }

  // ========================================================================
  // 私有方法
  // ========================================================================

  /// 获取或创建session_id
  Future<String> _getOrCreateSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    String? sessionId = prefs.getString('analytics_session_id');

    if (sessionId == null) {
      sessionId = _uuid.v4();
      await prefs.setString('analytics_session_id', sessionId);
    }

    return sessionId;
  }

  /// 获取设备信息
  Map<String, dynamic> _getDeviceInfo() {
    return {
      'platform': defaultTargetPlatform.name,
      'is_web': kIsWeb,
      'app_version': '1.0.0', // TODO: 从 package_info_plus 获取
      'os_version': '', // TODO: 从 device_info_plus 获取
    };
  }

  /// 保存队列到本地
  Future<void> _saveQueueToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_eventQueue.map((e) => e.toJson()).toList());
      await prefs.setString('analytics_queue', json);
    } catch (e) {
      if (kDebugMode) {
        print('[Analytics] Save queue failed: $e');
      }
    }
  }

  /// 从本地恢复队列
  Future<void> _restoreQueueFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('analytics_queue');

      if (json != null) {
        final List<dynamic> list = jsonDecode(json);
        _eventQueue.addAll(
          list.map((e) => AnalyticsEvent.fromJson(e)).toList(),
        );

        if (kDebugMode) {
          print('[Analytics] Restored ${_eventQueue.length} events from local');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[Analytics] Restore queue failed: $e');
      }
    }
  }

  /// 清除本地队列
  Future<void> _clearLocalQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('analytics_queue');
    } catch (e) {
      if (kDebugMode) {
        print('[Analytics] Clear queue failed: $e');
      }
    }
  }

  /// 释放资源
  void dispose() {
    _flushTimer?.cancel();
    flush();
  }
}

/// 分析事件模型
class AnalyticsEvent {
  final String eventType;
  final String? userId;
  final String sessionId;
  final String? contentId;
  final Map<String, dynamic> properties;
  final Map<String, dynamic> deviceInfo;
  final DateTime timestamp;

  AnalyticsEvent({
    required this.eventType,
    this.userId,
    required this.sessionId,
    this.contentId,
    required this.properties,
    required this.deviceInfo,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'event_type': eventType,
      'user_id': userId,
      'session_id': sessionId,
      'content_id': contentId,
      'properties': properties,
      'device_info': deviceInfo,
      'created_at': timestamp.toIso8601String(),
    };
  }

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      eventType: json['event_type'],
      userId: json['user_id'],
      sessionId: json['session_id'],
      contentId: json['content_id'],
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      deviceInfo: Map<String, dynamic>.from(json['device_info'] ?? {}),
      timestamp: DateTime.parse(json['created_at']),
    );
  }
}
