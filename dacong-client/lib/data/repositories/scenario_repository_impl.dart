import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/domain/entities/scenario.dart';
import '../../core/domain/repositories/i_scenario_repository.dart';
import '../../core/error/failures.dart';

/// 场景仓储实现（占位符）
@LazySingleton(as: IScenarioRepository)
class ScenarioRepositoryImpl implements IScenarioRepository {
  @override
  Future<Either<Failure, List<Scenario>>> getAllScenarios() async {
    // TODO: 实现从 Supabase 获取场景
    return const Right([]);
  }

  @override
  Future<Either<Failure, Scenario>> getScenarioById(String scenarioId) async {
    // TODO: 实现从 Supabase 获取场景详情
    return const Left(NotFoundFailure('场景不存在'));
  }
}
