import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/error/auth_failure.dart';
import '../../entities/auth_session.dart';
import '../../repositories/i_auth_repository.dart';

@injectable
class RegisterUseCase {
  final IAuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<Either<AuthFailure, AuthSession>> call({
    required String email,
    required String password,
    String? username,
  }) {
    return _repository.register(
      email: email,
      password: password,
      username: username,
    );
  }
}
