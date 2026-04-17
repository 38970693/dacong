import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/error/failures.dart';
import '../../entities/user.dart';
import '../../repositories/i_user_repository.dart';

/// 获取当前用户信息用例
@lazySingleton
class GetCurrentUser {
  final IUserRepository _repository;

  GetCurrentUser(this._repository);

  Future<Either<Failure, User>> call() {
    return _repository.getCurrentUser();
  }
}
