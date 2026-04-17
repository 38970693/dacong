import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/feedback.dart';
import '../repositories/i_feedback_repository.dart';
import '../../error/failures.dart';

/// 提交反馈用例
@injectable
class SubmitFeedback {
  final IFeedbackRepository _repository;

  SubmitFeedback(this._repository);

  Future<Either<Failure, UserFeedback>> call({
    required String contentId,
    required FeedbackType type,
    String? comment,
  }) async {
    return await _repository.submitFeedback(
      contentId: contentId,
      type: type,
      comment: comment,
    );
  }
}
