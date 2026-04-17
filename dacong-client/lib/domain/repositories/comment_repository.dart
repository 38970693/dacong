import 'package:dartz/dartz.dart';
import '../entities/comment.dart';
import '../../core/error/failures.dart';

/// 评论仓储接口
abstract class CommentRepository {
  /// 获取评论列表
  Future<Either<Failure, List<Comment>>> getComments({
    required String contentId,
    String? parentId,
    int page = 1,
    int limit = 20,
    String sort = 'latest',
  });

  /// 提交评论
  Future<Either<Failure, Comment>> submitComment({
    required String contentId,
    required String content,
    String? parentId,
  });

  /// 点赞评论
  Future<Either<Failure, void>> likeComment(String commentId);

  /// 取消点赞
  Future<Either<Failure, void>> unlikeComment(String commentId);

  /// 举报评论
  Future<Either<Failure, void>> reportComment({
    required String commentId,
    String? reason,
  });
}
