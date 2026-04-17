import 'package:dartz/dartz.dart';
import '../entities/weekly.dart';
import '../../error/failures.dart';

/// 周报仓储接口
abstract class WeeklyRepository {
  /// 获取最新周报
  Future<Either<Failure, Weekly>> getLatestWeekly();

  /// 获取历史周报列表
  Future<Either<Failure, List<Weekly>>> getWeeklyHistory({int limit = 10});

  /// 记录分享次数
  Future<Either<Failure, void>> recordShare(String weeklyId);
}
