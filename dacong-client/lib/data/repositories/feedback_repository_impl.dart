import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/domain/entities/feedback.dart';
import '../../core/domain/repositories/i_feedback_repository.dart';
import '../../core/error/failures.dart';
import '../datasources/remote_data_source.dart';

/// 反馈仓储实现
@LazySingleton(as: IFeedbackRepository)
class FeedbackRepositoryImpl implements IFeedbackRepository {
  final RemoteDataSource _remoteDataSource;

  FeedbackRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, UserFeedback>> submitFeedback({
    required String contentId,
    required FeedbackType type,
    String? comment,
  }) async {
    try {
      await _remoteDataSource.submitFeedback(
        contentId: contentId,
        userId: 'anonymous', // TODO: 获取真实用户 ID
        type: type.name,
        comment: comment,
      );

      return Right(UserFeedback(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contentId: contentId,
        userId: 'anonymous',
        type: type,
        comment: comment,
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      return Left(ServerFailure('提交反馈失败: $e'));
    }
  }

  @override
  Future<Either<Failure, UserFeedback?>> getUserFeedback(
    String contentId,
  ) async {
    // TODO: 实现获取用户反馈
    return const Right(null);
  }
}
