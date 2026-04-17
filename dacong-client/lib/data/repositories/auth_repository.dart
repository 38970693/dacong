import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../core/error/auth_failure.dart';
import '../datasources/supabase_auth_data_source.dart';

@LazySingleton(as: IAuthRepository)
class AuthRepository implements IAuthRepository {
  final SupabaseAuthDataSource _dataSource;

  AuthRepository(this._dataSource);

  @override
  Future<Either<AuthFailure, AuthSession>> register({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      final session = await _dataSource.register(
        email: email,
        password: password,
        username: username,
      );
      return right(session);
    } on AuthFailure catch (e) {
      return left(e);
    } catch (e) {
      return left(AuthFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, AuthSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _dataSource.login(
        email: email,
        password: password,
      );
      return right(session);
    } on AuthFailure catch (e) {
      return left(e);
    } catch (e) {
      return left(AuthFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> logout() async {
    try {
      await _dataSource.logout();
      return right(unit);
    } on AuthFailure catch (e) {
      return left(e);
    } catch (e) {
      return left(AuthFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> sendPasswordResetEmail(String email) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);
      return right(unit);
    } on AuthFailure catch (e) {
      return left(e);
    } catch (e) {
      return left(AuthFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    // Supabase handles password reset via email link
    // This would be called after user clicks the link
    return left(const AuthFailure.serverError('Not implemented'));
  }

  @override
  Future<Either<AuthFailure, Unit>> sendEmailVerification() async {
    // Supabase automatically sends verification email on signup
    return right(unit);
  }

  @override
  Future<Either<AuthFailure, Unit>> verifyEmail(String token) async {
    // Supabase handles email verification via link
    return right(unit);
  }

  @override
  Future<Either<AuthFailure, User>> getCurrentUser() async {
    try {
      final user = await _dataSource.getCurrentUser();
      return right(user);
    } on AuthFailure catch (e) {
      return left(e);
    } catch (e) {
      return left(AuthFailure.unknown(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, User>> updateProfile({
    String? username,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final user = await _dataSource.updateProfile(
        username: username,
        avatarUrl: avatarUrl,
        bio: bio,
      );
      return right(user);
    } on AuthFailure catch (e) {
      return left(e);
    } catch (e) {
      return left(AuthFailure.unknown(e.toString()));
    }
  }

  @override
  Stream<User?> get authStateChanges => _dataSource.authStateChanges;

  @override
  Future<Either<AuthFailure, AuthSession>> refreshToken() async {
    try {
      final session = await _dataSource.refreshToken();
      return right(session);
    } on AuthFailure catch (e) {
      return left(e);
    } catch (e) {
      return left(AuthFailure.unknown(e.toString()));
    }
  }
}
