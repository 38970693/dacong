import 'package:dartz/dartz.dart';
import '../../repositories/comment_repository.dart';
import '../../../core/error/failures.dart';

/// 举报评论用例
class ReportComment {
  final CommentRepository repository;

  ReportComment(this.repository);

  Future<Either<Failure, void>> call({
    required String commentId,
    String? reason,
  }) async {
    return await repository.reportComment(
      commentId: commentId,
      reason: reason,
    );
  }
}
