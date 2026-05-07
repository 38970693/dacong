import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/domain/entities/content.dart';
import '../../../core/domain/entities/feedback.dart';

part 'content_detail_state.freezed.dart';

/// ContentDetail 状态
@freezed
abstract class ContentDetailState with _$ContentDetailState {
  /// 初始状态
  const factory ContentDetailState.initial() = ContentDetailInitial;

  /// 加载中
  const factory ContentDetailState.loading() = ContentDetailLoading;

  /// 加载成功
  const factory ContentDetailState.loaded({
    required Content content,
    required List<Content> relatedContent,
    UserFeedback? userFeedback,
    required bool isFavorite,
  }) = ContentDetailLoaded;

  /// 加载失败
  const factory ContentDetailState.error(String message) = ContentDetailError;

  /// 提交反馈中
  const factory ContentDetailState.submittingFeedback({
    required Content content,
    required List<Content> relatedContent,
    UserFeedback? userFeedback,
    required bool isFavorite,
  }) = ContentDetailSubmittingFeedback;

  /// 反馈提交成功
  const factory ContentDetailState.feedbackSubmitted({
    required Content content,
    required List<Content> relatedContent,
    required UserFeedback userFeedback,
    required bool isFavorite,
  }) = ContentDetailFeedbackSubmitted;
}
