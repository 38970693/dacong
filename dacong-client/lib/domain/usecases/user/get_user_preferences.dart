import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/error/failures.dart';
import '../../entities/user.dart';
import '../../repositories/i_user_repository.dart';

/// 获取用户偏好设置用例
@lazySingleton
class GetUserPreferences {
  final IUserRepository _repository;

  GetUserPreferences(this._repository);

  Future<Either<Failure, UserPreferences>> call() {
    return _repository.getUserPreferences();
  }
}
