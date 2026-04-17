import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/domain/entities/feedback.dart';

part 'content_detail_event.freezed.dart';

/// ContentDetail 事件
@freezed
class ContentDetailEvent with _$ContentDetailEvent {
  /// 加载内容详情
  const factory ContentDetailEvent.loadContentDetail(String contentId) =
      LoadContentDetail;

  /// 提交反馈
  const factory ContentDetailEvent.submitFeedback({
    required String contentId,
    required FeedbackType type,
    String? comment,
  }) = SubmitFeedbackEvent;

  /// 切换收藏状态
  const factory ContentDetailEvent.toggleFavorite(String contentId) =
      ToggleFavorite;

  /// 分享内容
  const factory ContentDetailEvent.shareContent(String contentId) =
      ShareContent;
}
