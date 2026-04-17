import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/error/failures.dart';
import '../../entities/user.dart';
import '../../repositories/i_user_repository.dart';

/// 获取浏览历史用例
@lazySingleton
class GetHistory {
  final IUserRepository _repository;

  GetHistory(this._repository);

  Future<Either<Failure, List<HistoryItem>>> call({int limit = 50}) {
    return _repository.getHistory(limit: limit);
  }
}

/// 添加浏览历史用例
@lazySingleton
class AddHistory {
  final IUserRepository _repository;

  AddHistory(this._repository);

  Future<Either<Failure, Unit>> call(HistoryItem item) {
    return _repository.addHistory(item);
  }
}

/// 清空浏览历史用例
@lazySingleton
class ClearHistory {
  final IUserRepository _repository;

  ClearHistory(this._repository);

  Future<Either<Failure, Unit>> call() {
    return _repository.clearHistory();
  }
}
