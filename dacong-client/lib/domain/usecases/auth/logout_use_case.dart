import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../core/error/auth_failure.dart';
import '../repositories/i_auth_repository.dart';

@injectable
class LogoutUseCase {
  final IAuthRepository _repository;

  LogoutUseCase(this._repository);

  Future<Either<AuthFailure, Unit>> call() {
    return _repository.logout();
  }
}
