import 'package:dartz/dartz.dart';
import '../entities/feedback.dart';
import '../../error/failures.dart';

/// 反馈仓储接口
abstract class IFeedbackRepository {
  /// 提交反馈
  Future<Either<Failure, UserFeedback>> submitFeedback({
    required String contentId,
    required FeedbackType type,
    String? comment,
  });

  /// 获取用户对某内容的反馈
  Future<Either<Failure, UserFeedback?>> getUserFeedback(String contentId);
}
