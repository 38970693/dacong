import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback.freezed.dart';

/// 用户反馈实体（不可变）
@freezed
class UserFeedback with _$UserFeedback {
  const factory UserFeedback({
    required String id,
    required String contentId,
    required String? userId,
    required FeedbackType type,
    required String? comment,
    required DateTime createdAt,
  }) = _UserFeedback;
}

/// 反馈类型
enum FeedbackType {
  helpful,    // 有用
  unhelpful,  // 无用
}
