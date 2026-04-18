import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/favorite_content.dart';

part 'user_state.freezed.dart';

/// 用户状态
@freezed
class UserState with _$UserState {
  const factory UserState({
    @Default(false) bool isLoading,
    User? user,
    UserPreferences? preferences,
    @Default([]) List<String> favorites,
    @Default([]) List<FavoriteContent> favoriteContents,
    @Default([]) List<HistoryItem> history,
    String? error,
  }) = _UserState;

  factory UserState.initial() => const UserState();
}
