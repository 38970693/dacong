import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../domain/entities/user.dart';

part 'user_event.freezed.dart';

/// 用户事件
@freezed
abstract class UserEvent with _$UserEvent {
  /// 加载用户信息
  const factory UserEvent.loadUser() = LoadUser;

  /// 更新用户资料
  const factory UserEvent.updateProfile({
    String? username,
    String? avatarUrl,
    String? bio,
  }) = UpdateProfile;

  /// 切换语言
  const factory UserEvent.toggleLanguage(String language) = ToggleLanguage;

  /// 切换主题
  const factory UserEvent.toggleTheme(String theme) = ToggleTheme;

  /// 切换通知设置
  const factory UserEvent.toggleNotifications(bool enabled) = ToggleNotifications;

  /// 切换周报推送
  const factory UserEvent.toggleWeeklyReport(bool enabled) = ToggleWeeklyReport;

  /// 切换工具更新通知
  const factory UserEvent.toggleToolUpdate(bool enabled) = ToggleToolUpdate;

  /// 添加收藏
  const factory UserEvent.addFavorite(String contentId) = AddFavorite;

  /// 移除收藏
  const factory UserEvent.removeFavorite(String contentId) = RemoveFavorite;

  /// 加载收藏列表
  const factory UserEvent.loadFavorites() = LoadFavorites;

  /// 添加浏览历史
  const factory UserEvent.addHistory(HistoryItem item) = AddHistory;

  /// 加载浏览历史
  const factory UserEvent.loadHistory() = LoadHistory;

  /// 清空浏览历史
  const factory UserEvent.clearHistory() = ClearHistory;
}
