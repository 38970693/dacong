import 'package:dartz/dartz.dart';
import '../../entities/comment.dart';
import '../../repositories/comment_repository.dart';
import '../../../core/error/failures.dart';

/// 提交评论用例
class SubmitComment {
  final CommentRepository repository;

  SubmitComment(this.repository);

  Future<Either<Failure, Comment>> call({
    required String contentId,
    required String content,
    String? parentId,
  }) async {
    // 验证评论内容
    if (content.trim().isEmpty) {
      return Left(ValidationFailure('Comment cannot be empty'));
    }

    if (content.length > 2000) {
      return Left(ValidationFailure('Comment is too long (max 2000 characters)'));
    }

    return await repository.submitComment(
      contentId: contentId,
      content: content.trim(),
      parentId: parentId,
    );
  }
}
