import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/scenario.dart';
import '../repositories/i_scenario_repository.dart';
import '../../error/failures.dart';

/// 获取所有场景用例
@injectable
class GetAllScenarios {
  final IScenarioRepository _repository;

  GetAllScenarios(this._repository);

  Future<Either<Failure, List<Scenario>>> call() async {
    return await _repository.getAllScenarios();
  }
}
