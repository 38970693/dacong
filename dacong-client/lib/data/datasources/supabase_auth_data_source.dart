import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/entities/auth_session.dart';
import '../../core/error/auth_failure.dart';

@injectable
class SupabaseAuthDataSource {
  final SupabaseClient _client;

  SupabaseAuthDataSource(this._client);

  /// 注册新用户
  Future<AuthSession> register({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: username != null ? {'username': username} : null,
      );

      if (response.user == null || response.session == null) {
        throw const AuthFailure.serverError('Registration failed');
      }

      return _mapToAuthSession(response.session!, response.user!);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthFailure.unknown(e.toString());
    }
  }

  /// 用户登录
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null || response.session == null) {
        throw const AuthFailure.invalidCredentials();
      }

      return _mapToAuthSession(response.session!, response.user!);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthFailure.unknown(e.toString());
    }
  }

  /// 用户登出
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthFailure.unknown(e.toString());
    }
  }

  /// 发送密码重置邮件
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthFailure.unknown(e.toString());
    }
  }

  /// 获取当前用户
  Future<domain.User> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw const AuthFailure.userNotFound();
      }
      return _mapToUser(user);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure.unknown(e.toString());
    }
  }

  /// 更新用户资料
  Future<domain.User> updateProfile({
    String? username,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (bio != null) updates['bio'] = bio;

      final response = await _client.auth.updateUser(
        UserAttributes(data: updates),
      );

      if (response.user == null) {
        throw const AuthFailure.serverError('Update failed');
      }

      return _mapToUser(response.user!);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthFailure.unknown(e.toString());
    }
  }

  /// 监听认证状态变化
  Stream<domain.User?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      return user != null ? _mapToUser(user) : null;
    });
  }

  /// 刷新 Token
  Future<AuthSession> refreshToken() async {
    try {
      final response = await _client.auth.refreshSession();
      if (response.session == null || response.user == null) {
        throw const AuthFailure.serverError('Token refresh failed');
      }
      return _mapToAuthSession(response.session!, response.user!);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthFailure.unknown(e.toString());
    }
  }

  /// 映射 Supabase User 到 Domain User
  domain.User _mapToUser(User user) {
    return domain.User(
      id: user.id,
      email: user.email ?? '',
      username: user.userMetadata?['username'] as String?,
      avatarUrl: user.userMetadata?['avatar_url'] as String?,
      bio: user.userMetadata?['bio'] as String?,
      emailVerified: user.emailConfirmedAt != null,
      createdAt: user.createdAt != null ? DateTime.parse(user.createdAt) : null,
      updatedAt: user.updatedAt != null ? DateTime.parse(user.updatedAt!) : null,
    );
  }

  /// 映射到 AuthSession
  AuthSession _mapToAuthSession(Session session, User user) {
    return AuthSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken ?? '',
      user: _mapToUser(user),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000),
    );
  }

  /// 映射 Supabase AuthException 到 AuthFailure
  AuthFailure _mapAuthException(AuthException exception) {
    final message = exception.message.toLowerCase();

    // 检查邮箱未验证的错误
    if (message.contains('email not confirmed') ||
        message.contains('email_not_confirmed') ||
        exception.statusCode == '422') {
      return const AuthFailure.emailNotVerified();
    }

    // 检查邮件频率限制
    if (message.contains('rate limit') ||
        message.contains('too many requests') ||
        message.contains('email rate limit')) {
      return const AuthFailure.emailRateLimit();
    }

    switch (exception.statusCode) {
      case '400':
        if (message.contains('invalid login credentials')) {
          return const AuthFailure.invalidCredentials();
        }
        if (message.contains('user already registered')) {
          return const AuthFailure.emailAlreadyInUse();
        }
        if (message.contains('password')) {
          return const AuthFailure.weakPassword();
        }
        return AuthFailure.serverError(exception.message);
      case '404':
        return const AuthFailure.userNotFound();
      case '429':
        return const AuthFailure.emailRateLimit();
      default:
        return AuthFailure.serverError(exception.message);
    }
  }
}
