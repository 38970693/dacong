import 'package:dartz/dartz.dart';
import '../entities/content.dart';
import '../entities/recommendation.dart';
import '../../error/failures.dart';

/// 内容仓储接口（依赖倒置原则）
abstract class IContentRepository {
  /// 获取场景推荐列表
  Future<Either<Failure, List<Recommendation>>> getRecommendationsByScenario(
    String scenario,
  );

  /// 获取内容详情
  Future<Either<Failure, Content>> getContentById(String contentId);

  /// 获取相关推荐
  Future<Either<Failure, List<Content>>> getRelatedContent(
    String contentId, {
    int limit = 3,
  });

  /// 搜索内容
  Future<Either<Failure, List<Content>>> searchContent(
    String query, {
    int limit = 20,
    int offset = 0,
    String? scenario,
    bool? isFree,
    bool? availableInChina,
    String sortBy = 'relevance',
  });
}
