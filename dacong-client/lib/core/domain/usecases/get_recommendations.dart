import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/recommendation.dart';
import '../repositories/i_content_repository.dart';
import '../../error/failures.dart';

/// 获取推荐用例（单一职责原则）
@injectable
class GetRecommendations {
  final IContentRepository _repository;

  GetRecommendations(this._repository);

  /// 执行用例
  Future<Either<Failure, List<Recommendation>>> call(String scenario) async {
    return await _repository.getRecommendationsByScenario(scenario);
  }
}
