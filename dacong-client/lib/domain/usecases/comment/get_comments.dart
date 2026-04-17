import 'package:dartz/dartz.dart';
import '../../entities/comment.dart';
import '../../repositories/comment_repository.dart';
import '../../../core/error/failures.dart';

/// 获取评论列表用例
class GetComments {
  final CommentRepository repository;

  GetComments(this.repository);

  Future<Either<Failure, List<Comment>>> call({
    required String contentId,
    String? parentId,
    int page = 1,
    int limit = 20,
    String sort = 'latest',
  }) async {
    return await repository.getComments(
      contentId: contentId,
      parentId: parentId,
      page: page,
      limit: limit,
      sort: sort,
    );
  }
}
