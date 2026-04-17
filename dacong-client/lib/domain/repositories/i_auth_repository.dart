import 'package:dartz/dartz.dart';
import '../entities/user.dart';
import '../entities/auth_session.dart';
import '../../core/error/auth_failure.dart';

abstract class IAuthRepository {
  /// 用户注册
  Future<Either<AuthFailure, AuthSession>> register({
    required String email,
    required String password,
    String? username,
  });

  /// 用户登录
  Future<Either<AuthFailure, AuthSession>> login({
    required String email,
    required String password,
  });

  /// 用户登出
  Future<Either<AuthFailure, Unit>> logout();

  /// 发送密码重置邮件
  Future<Either<AuthFailure, Unit>> sendPasswordResetEmail(String email);

  /// 重置密码
  Future<Either<AuthFailure, Unit>> resetPassword({
    required String token,
    required String newPassword,
  });

  /// 发送邮箱验证邮件
  Future<Either<AuthFailure, Unit>> sendEmailVerification();

  /// 验证邮箱
  Future<Either<AuthFailure, Unit>> verifyEmail(String token);

  /// 获取当前用户
  Future<Either<AuthFailure, User>> getCurrentUser();

  /// 更新用户资料
  Future<Either<AuthFailure, User>> updateProfile({
    String? username,
    String? avatarUrl,
    String? bio,
  });

  /// 检查认证状态
  Stream<User?> get authStateChanges;

  /// 刷新 Token
  Future<Either<AuthFailure, AuthSession>> refreshToken();
}
