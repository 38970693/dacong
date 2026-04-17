import 'package:dartz/dartz.dart';
import '../../repositories/comment_repository.dart';
import '../../../core/error/failures.dart';

/// 取消点赞用例
class UnlikeComment {
  final CommentRepository repository;

  UnlikeComment(this.repository);

  Future<Either<Failure, void>> call(String commentId) async {
    return await repository.unlikeComment(commentId);
  }
}
