import 'package:flutter/foundation.dart';
import '../../domain/entities/notification.dart';
import '../../domain/usecases/notification_usecases.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/datasources/remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 通知状态
class NotificationState {
  final List<Notification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
  });

  NotificationState copyWith({
    List<Notification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// 通知提供者
class NotificationProvider extends ChangeNotifier {
  final GetNotifications _getNotifications;
  final MarkNotificationAsRead _markAsRead;
  final MarkAllNotificationsAsRead _markAllAsRead;

  NotificationState _state = const NotificationState();
  NotificationState get state => _state;

  NotificationProvider({
    required GetNotifications getNotifications,
    required MarkNotificationAsRead markAsRead,
    required MarkAllNotificationsAsRead markAllAsRead,
  })  : _getNotifications = getNotifications,
        _markAsRead = markAsRead,
        _markAllAsRead = markAllAsRead;

  // 工厂构造函数
  factory NotificationProvider.create() {
    final supabase = Supabase.instance.client;
    final remoteDataSource = RemoteDataSource(supabase);
    final repository = NotificationRepositoryImpl(remoteDataSource);

    return NotificationProvider(
      getNotifications: GetNotifications(repository),
      markAsRead: MarkNotificationAsRead(repository),
      markAllAsRead: MarkAllNotificationsAsRead(repository),
    );
  }

  int get unreadCount => _state.unreadCount;
  List<Notification> get notifications => _state.notifications;
  bool get isLoading => _state.isLoading;
  bool get hasMore => _state.hasMore;

  /// 加载通知列表
  Future<void> loadNotifications({bool unreadOnly = false}) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final result = await _getNotifications(
        page: 1,
        pageSize: 20,
        unreadOnly: unreadOnly,
      );

      _state = NotificationState(
        notifications: result['notifications'] as List<Notification>,
        unreadCount: result['unreadCount'] as int,
        isLoading: false,
        currentPage: 1,
        hasMore: (result['totalPages'] as int) > 1,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  /// 加载更多
  Future<void> loadMore() async {
    if (_state.isLoading || !_state.hasMore) return;

    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      final result = await _getNotifications(
        page: _state.currentPage + 1,
        pageSize: 20,
      );

      final newNotifications = result['notifications'] as List<Notification>;
      _state = _state.copyWith(
        notifications: [..._state.notifications, ...newNotifications],
        unreadCount: result['unreadCount'] as int,
        isLoading: false,
        currentPage: _state.currentPage + 1,
        hasMore: (result['totalPages'] as int) > (_state.currentPage + 1),
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  /// 标记为已读
  Future<void> markAsRead(String notificationId) async {
    try {
      await _markAsRead(notificationId);

      // 更新本地状态
      final updatedNotifications = _state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      _state = _state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
    }
  }

  /// 标记所有为已读
  Future<void> markAllAsRead() async {
    try {
      await _markAllAsRead();

      // 更新本地状态
      final updatedNotifications = _state.notifications.map((n) {
        return n.copyWith(isRead: true);
      }).toList();

      _state = _state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
    }
  }
}

// 全局实例
final notificationProvider = NotificationProvider.create();
