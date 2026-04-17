import 'package:dartz/dartz.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../core/error/failures.dart';
import '../datasources/comment_remote_data_source.dart';

/// 评论仓储实现
class CommentRepositoryImpl implements CommentRepository {
  final CommentRemoteDataSource remoteDataSource;

  CommentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Comment>>> getComments({
    required String contentId,
    String? parentId,
    int page = 1,
    int limit = 20,
    String sort = 'latest',
  }) async {
    try {
      final comments = await remoteDataSource.getComments(
        contentId: contentId,
        parentId: parentId,
        page: page,
        limit: limit,
        sort: sort,
      );
      return Right(comments.map((model) => model as Comment).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Comment>> submitComment({
    required String contentId,
    required String content,
    String? parentId,
  }) async {
    try {
      final comment = await remoteDataSource.submitComment(
        contentId: contentId,
        content: content,
        parentId: parentId,
      );
      return Right(comment as Comment);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> likeComment(String commentId) async {
    try {
      await remoteDataSource.likeComment(commentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unlikeComment(String commentId) async {
    try {
      await remoteDataSource.unlikeComment(commentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reportComment({
    required String commentId,
    String? reason,
  }) async {
    try {
      await remoteDataSource.reportComment(
        commentId: commentId,
        reason: reason,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
