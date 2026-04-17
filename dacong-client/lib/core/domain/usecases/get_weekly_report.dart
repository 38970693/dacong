import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/weekly.dart';
import '../repositories/weekly_repository.dart';
import '../../error/failures.dart';

/// 获取周报 Use Case
@injectable
class GetWeeklyReport {
  final WeeklyRepository _repository;

  GetWeeklyReport(this._repository);

  /// 获取最新周报
  Future<Either<Failure, Weekly>> call() async {
    return await _repository.getLatestWeekly();
  }

  /// 获取历史周报列表
  Future<Either<Failure, List<Weekly>>> getHistory({int limit = 10}) async {
    return await _repository.getWeeklyHistory(limit: limit);
  }
}
