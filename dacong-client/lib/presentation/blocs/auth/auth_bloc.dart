import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../core/error/auth_failure.dart';
import '../../../domain/usecases/auth/login_use_case.dart';
import '../../../domain/usecases/auth/register_use_case.dart';
import '../../../domain/usecases/auth/logout_use_case.dart';
import '../../../domain/usecases/auth/get_current_user_use_case.dart';
import '../../../domain/usecases/auth/update_profile_use_case.dart';
import '../../../domain/usecases/auth/send_password_reset_email_use_case.dart';
import '../../../domain/repositories/i_auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final SendPasswordResetEmailUseCase _sendPasswordResetEmailUseCase;
  final IAuthRepository _authRepository;

  StreamSubscription? _authStateSubscription;

  AuthBloc(
    this._loginUseCase,
    this._registerUseCase,
    this._logoutUseCase,
    this._getCurrentUserUseCase,
    this._updateProfileUseCase,
    this._sendPasswordResetEmailUseCase,
    this._authRepository,
  ) : super(const AuthState.initial()) {
    on<AuthEvent>(_onEvent);

    _authStateSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        add(AuthEvent.authCheckRequested());
      }
    });
  }

  Future<void> _onEvent(AuthEvent event, Emitter<AuthState> emit) async {
    await event.maybeWhen(
      authCheckRequested: () async {
        emit(const AuthState.loading());
        final result = await _getCurrentUserUseCase();
        result.fold(
          (failure) => emit(const AuthState.unauthenticated()),
          (user) => emit(AuthState.authenticated(user)),
        );
      },
      loginRequested: (email, password) async {
        emit(const AuthState.loading());
        final result = await _loginUseCase(email: email, password: password);
        result.fold(
          (failure) {
            if (failure is AuthFailure) {
              failure.maybeWhen(
                emailNotVerified: () => emit(const AuthState.emailNotVerified()),
                orElse: () => emit(AuthState.error(_mapFailureToMessage(failure))),
              );
            } else {
              emit(AuthState.error(_mapFailureToMessage(failure)));
            }
          },
          (session) => emit(AuthState.authenticated(session.user)),
        );
      },
      registerRequested: (email, password, username) async {
        emit(const AuthState.loading());
        final result = await _registerUseCase(
          email: email,
          password: password,
          username: username,
        );
        result.fold(
          (failure) => emit(AuthState.error(_mapFailureToMessage(failure))),
          (session) => emit(AuthState.authenticated(session.user)),
        );
      },
      logoutRequested: () async {
        emit(const AuthState.loading());
        final result = await _logoutUseCase();
        result.fold(
          (failure) => emit(AuthState.error(_mapFailureToMessage(failure))),
          (_) => emit(const AuthState.unauthenticated()),
        );
      },
      passwordResetRequested: (email) async {
        final currentState = state;
        emit(const AuthState.loading());
        final result = await _sendPasswordResetEmailUseCase(email);
        result.fold(
          (failure) => emit(AuthState.error(_mapFailureToMessage(failure))),
          (_) => emit(currentState),
        );
      },
      profileUpdateRequested: (username, avatarUrl, bio) async {
        emit(const AuthState.loading());
        final result = await _updateProfileUseCase(
          username: username,
          avatarUrl: avatarUrl,
          bio: bio,
        );
        result.fold(
          (failure) => emit(AuthState.error(_mapFailureToMessage(failure))),
          (user) => emit(AuthState.authenticated(user)),
        );
      },
      orElse: () async {},
    );
  }

  String _mapFailureToMessage(dynamic failure) {
    return failure.when(
      invalidCredentials: () => '邮箱或密码错误',
      emailAlreadyInUse: () => '该邮箱已被注册',
      weakPassword: () => '密码强度不足',
      userNotFound: () => '用户不存在',
      emailNotVerified: () => '请查收验证邮件并点击链接完成验证',
      networkError: () => '网络连接失败',
      emailRateLimit: () => '发送邮件过于频繁，请稍后再试',
      serverError: (message) => '服务器错误: $message',
      unknown: (message) => '未知错误: $message',
    );
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
