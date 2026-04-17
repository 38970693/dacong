import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/error/failures.dart';
import '../../entities/user.dart';
import '../../repositories/i_user_repository.dart';

/// 更新用户偏好设置用例
@lazySingleton
class UpdateUserPreferences {
  final IUserRepository _repository;

  UpdateUserPreferences(this._repository);

  Future<Either<Failure, Unit>> call(UserPreferences preferences) {
    return _repository.updateUserPreferences(preferences);
  }
}
