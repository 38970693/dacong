import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/domain/entities/recommendation.dart';

part 'recommendation_model.freezed.dart';
part 'recommendation_model.g.dart';

@freezed
class RecommendationModel with _$RecommendationModel {
  const factory RecommendationModel({
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
    required String type,
  }) = _RecommendationModel;

  const RecommendationModel._();

  factory RecommendationModel.fromJson(Map<String, dynamic> json) =>
      _$RecommendationModelFromJson(json);

  Recommendation toEntity() {
    return Recommendation(
      id: id,
      contentId: contentId,
      scenario: scenario,
      toolName: toolName,
      description: description,
      pros: pros,
      cons: cons,
      targetAudience: targetAudience,
      price: price,
      availableInChina: availableInChina,
      rating: rating,
      rank: rank,
      type: _parseType(type),
    );
  }

  static RecommendationType _parseType(String value) {
    switch (value.toLowerCase()) {
      case 'best':
        return RecommendationType.best;
      case 'alternative':
        return RecommendationType.alternative;
      case 'free':
        return RecommendationType.free;
      default:
        return RecommendationType.best;
    }
  }
}
