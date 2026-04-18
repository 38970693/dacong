import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_content.freezed.dart';

/// 收藏的内容实体
@freezed
class FavoriteContent with _$FavoriteContent {
  const factory FavoriteContent({
    required String favoriteId,
    required String contentId,
    required String contentType,
    required String title,
    String? summary,
    String? scenario,
    @Default(0) int viewCount,
    @Default(0) int helpfulCount,
    @Default(0) int shareCount,
    required DateTime publishedAt,
    required DateTime favoritedAt,
  }) = _FavoriteContent;
}
