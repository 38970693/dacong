import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

/// 用户实体
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String email,
    String? username,
    String? avatarUrl,
    String? bio,
    @Default(false) bool emailVerified,
    @Default('zh') String language,
    @Default('system') String theme,
    @Default(true) bool notificationsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _User;
}

/// 用户偏好设置
@freezed
abstract class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    @Default('zh') String language,
    @Default('system') String theme, // 'light', 'dark', 'system'
    @Default(true) bool notificationsEnabled,
    @Default(true) bool weeklyReportEnabled,
    @Default(true) bool toolUpdateEnabled,
  }) = _UserPreferences;
}

/// 浏览历史项
@freezed
abstract class HistoryItem with _$HistoryItem {
  const factory HistoryItem({
    required String contentId,
    required String contentType, // 'recommendation', 'guide', 'weekly'
    required String title,
    String? summary,
    String? imageUrl,
    required DateTime viewedAt,
  }) = _HistoryItem;
}
