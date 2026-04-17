import 'package:freezed_annotation/freezed_annotation.dart';

part 'recommendation.freezed.dart';

/// 推荐实体（不可变）
@freezed
class Recommendation with _$Recommendation {
  const factory Recommendation({
    required String id,
    required String contentId,
    required String scenario,
    required String toolName,
    required String description,
    required List<String> pros,
    required List<String> cons,
    required String targetAudience,
    required String price,
    required bool availableInChina,
    required double rating,
    required int rank,
    required RecommendationType type,
  }) = _Recommendation;
}

/// 推荐类型
enum RecommendationType {
  best,      // 最佳
  alternative, // 平替
  free,      // 免费
}
