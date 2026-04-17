import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/error/auth_failure.dart';
import '../entities/auth_session.dart';
import '../repositories/i_auth_repository.dart';

@injectable
class LoginUseCase {
  final IAuthRepository _repository;

  LoginUseCase(this._repository);

  Future<Either<AuthFailure, AuthSession>> call({
    required String email,
    required String password,
  }) {
    return _repository.login(
      email: email,
      password: password,
    );
  }
}
