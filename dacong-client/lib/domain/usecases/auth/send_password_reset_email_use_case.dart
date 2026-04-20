import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/error/auth_failure.dart';
import '../../repositories/i_auth_repository.dart';

@injectable
class SendPasswordResetEmailUseCase {
  final IAuthRepository _repository;

  SendPasswordResetEmailUseCase(this._repository);

  Future<Either<AuthFailure, Unit>> call(String email) {
    return _repository.sendPasswordResetEmail(email);
  }
}
