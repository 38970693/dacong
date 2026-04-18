import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/domain/entities/content.dart';
import '../../core/domain/entities/recommendation.dart';
import '../../core/domain/repositories/i_content_repository.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../datasources/remote_data_source.dart';

/// 内容仓储实现（依赖倒置原则）
@LazySingleton(as: IContentRepository)
class ContentRepositoryImpl implements IContentRepository {
  final RemoteDataSource _remoteDataSource;

  ContentRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Recommendation>>> getRecommendationsByScenario(
    String scenario,
  ) async {
    try {
      final models = await _remoteDataSource.getRecommendationsByScenario(scenario);
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('未知错误: $e'));
    }
  }

  @override
  Future<Either<Failure, Content>> getContentById(String contentId) async {
    try {
      final model = await _remoteDataSource.getContentById(contentId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('未知错误: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Content>>> getRelatedContent(
    String contentId, {
    int limit = 3,
  }) async {
    try {
      final models = await _remoteDataSource.getRelatedContent(
        contentId,
        limit: limit,
      );
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('未知错误: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Content>>> searchContent(
    String query, {
    int limit = 20,
    int offset = 0,
    String? scenario,
    bool? isFree,
    bool? availableInChina,
    String sortBy = 'relevance',
  }) async {
    try {
      final models = await _remoteDataSource.searchContent(
        query,
        limit: limit,
        offset: offset,
        scenario: scenario,
        isFree: isFree,
        availableInChina: availableInChina,
        sortBy: sortBy,
      );
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('未知错误: $e'));
    }
  }
}
