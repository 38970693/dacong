import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/error/auth_failure.dart';
import '../entities/user.dart';
import '../repositories/i_auth_repository.dart';

@injectable
class UpdateProfileUseCase {
  final IAuthRepository _repository;

  UpdateProfileUseCase(this._repository);

  Future<Either<AuthFailure, User>> call({
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
