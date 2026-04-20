import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/error/auth_failure.dart';
import '../../entities/user.dart';
import '../../repositories/i_auth_repository.dart';

@injectable
class GetCurrentUserUseCase {
  final IAuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  Future<Either<AuthFailure, User>> call() {
    return _repository.getCurrentUser();
  }
}
