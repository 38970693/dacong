import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum NotificationType {
  contentPendingReview,
  userReport,
  systemError,
  commentPendingReview,
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.data,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${json['type']}',
        orElse: () => NotificationType.systemError,
      ),
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      data: json['data'],
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'is_read': isRead,
    };
  }
}

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _notificationController = StreamController<NotificationItem>.broadcast();
  final List<NotificationItem> _notifications = [];

  StreamSubscription? _realtimeSubscription;
  Timer? _pollingTimer;

  Stream<NotificationItem> get notificationStream => _notificationController.stream;
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> initialize() async {
    // 加载历史通知
    await _loadNotifications();

    // 订阅实时通知
    _subscribeToRealtimeNotifications();

    // 定期轮询（作为实时订阅的备份）
    _startPolling();

    // 请求浏览器通知权限（仅 Web）
    if (kIsWeb) {
      await _requestBrowserNotificationPermission();
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await _supabase
          .from('admin_notifications')
          .select()
          .order('timestamp', ascending: false)
          .limit(50);

      _notifications.clear();
      _notifications.addAll(
        (response as List).map((item) => NotificationItem.fromJson(item)),
      );
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
    }
  }

  void _subscribeToRealtimeNotifications() {
    _realtimeSubscription = _supabase
        .from('admin_notifications')
        .stream(primaryKey: ['id'])
        .listen((data) {
          for (final item in data) {
            final notification = NotificationItem.fromJson(item);

            // 检查是否已存在
            final existingIndex = _notifications.indexWhere((n) => n.id == notification.id);
            if (existingIndex == -1) {
              _notifications.insert(0, notification);
              _notificationController.add(notification);

              // 显示浏览器通知
              if (kIsWeb && !notification.isRead) {
                _showBrowserNotification(notification);
              }
            } else {
              _notifications[existingIndex] = notification;
            }
          }
        });
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _checkForNewNotifications();
    });
  }

  Future<void> _checkForNewNotifications() async {
    try {
      final lastTimestamp = _notifications.isNotEmpty
          ? _notifications.first.timestamp
          : DateTime.now().subtract(const Duration(hours: 24));

      final response = await _supabase
          .from('admin_notifications')
          .select()
          .gt('timestamp', lastTimestamp.toIso8601String())
          .order('timestamp', ascending: false);

      for (final item in response as List) {
        final notification = NotificationItem.fromJson(item);
        _notifications.insert(0, notification);
        _notificationController.add(notification);

        if (kIsWeb && !notification.isRead) {
          _showBrowserNotification(notification);
        }
      }
    } catch (e) {
      debugPrint('Failed to check for new notifications: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('admin_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationItem(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          message: _notifications[index].message,
          timestamp: _notifications[index].timestamp,
          data: _notifications[index].data,
          isRead: true,
        );
      }
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final unreadIds = _notifications
          .where((n) => !n.isRead)
          .map((n) => n.id)
          .toList();

      if (unreadIds.isEmpty) return;

      for (final id in unreadIds) {
        await _supabase
            .from('admin_notifications')
            .update({'is_read': true})
            .eq('id', id);
      }

      for (var i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = NotificationItem(
            id: _notifications[i].id,
            type: _notifications[i].type,
            title: _notifications[i].title,
            message: _notifications[i].message,
            timestamp: _notifications[i].timestamp,
            data: _notifications[i].data,
            isRead: true,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to mark all notifications as read: $e');
    }
  }

  Future<void> _requestBrowserNotificationPermission() async {
    // Web 通知权限请求
    // 注意：这需要在 web/index.html 中添加相应的 JavaScript 代码
    if (kIsWeb) {
      // TODO: 实现 Web Notification API 调用
      debugPrint('Browser notification permission requested');
    }
  }

  void _showBrowserNotification(NotificationItem notification) {
    if (kIsWeb) {
      // TODO: 调用 Web Notification API
      debugPrint('Showing browser notification: ${notification.title}');
    }
  }

  Future<void> createNotification({
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.from('admin_notifications').insert({
        'type': type.toString().split('.').last,
        'title': title,
        'message': message,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'is_read': false,
      });
    } catch (e) {
      debugPrint('Failed to create notification: $e');
    }
  }

  void dispose() {
    _realtimeSubscription?.cancel();
    _pollingTimer?.cancel();
    _notificationController.close();
  }
}
