import 'package:dartz/dartz.dart';
import '../entities/scenario.dart';
import '../../error/failures.dart';

/// 场景仓储接口
abstract class IScenarioRepository {
  /// 获取所有场景
  Future<Either<Failure, List<Scenario>>> getAllScenarios();

  /// 获取场景详情
  Future<Either<Failure, Scenario>> getScenarioById(String scenarioId);
}
