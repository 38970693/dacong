import 'package:dartz/dartz.dart';
import '../../repositories/comment_repository.dart';
import '../../../core/error/failures.dart';

/// 点赞评论用例
class LikeComment {
  final CommentRepository repository;

  LikeComment(this.repository);

  Future<Either<Failure, void>> call(String commentId) async {
    return await repository.likeComment(commentId);
  }
}
