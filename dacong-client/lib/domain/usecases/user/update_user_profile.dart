import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/error/failures.dart';
import '../../entities/user.dart';
import '../../repositories/i_user_repository.dart';

/// 更新用户资料用例
@lazySingleton
class UpdateUserProfile {
  final IUserRepository _repository;

  UpdateUserProfile(this._repository);

  Future<Either<Failure, User>> call({
    String? username,
    String? avatarUrl,
    String? bio,
  }) {
    return _repository.updateProfile(
      username: username,
      avatarUrl: avatarUrl,
      bio: bio,
    );
  }
}
