import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
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
    on<_AuthCheckRequested>(_onAuthCheckRequested);
    on<_LoginRequested>(_onLoginRequested);
    on<_RegisterRequested>(_onRegisterRequested);
    on<_LogoutRequested>(_onLogoutRequested);
    on<_PasswordResetRequested>(_onPasswordResetRequested);
    on<_ProfileUpdateRequested>(_onProfileUpdateRequested);

    // 监听认证状态变化
    _authStateSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(const AuthState.unauthenticated());
      }
    });
  }

  Future<void> _onAuthCheckRequested(
    _AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    final result = await _getCurrentUserUseCase();

    result.fold(
      (failure) => emit(const AuthState.unauthenticated()),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  Future<void> _onLoginRequested(
    _LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    final result = await _loginUseCase(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) => emit(AuthState.error(_mapFailureToMessage(failure))),
      (session) => emit(AuthState.authenticated(session.user)),
    );
  }

  Future<void> _onRegisterRequested(
    _RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    final result = await _registerUseCase(
      email: event.email,
      password: event.password,
      username: event.username,
    );

    result.fold(
      (failure) => emit(AuthState.error(_mapFailureToMessage(failure))),
      (session) => emit(AuthState.authenticated(session.user)),
    );
  }

  Future<void> _onLogoutRequested(
    _LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    final result = await _logoutUseCase();

    result.fold(
      (failure) => emit(AuthState.error(_mapFailureToMessage(failure))),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }

  Future<void> _onPasswordResetRequested(
    _PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    emit(const AuthState.loading());

    final result = await _sendPasswordResetEmailUseCase(event.email);

    result.fold(
      (failure) => emit(AuthState.error(_mapFailureToMessage(failure))),
      (_) => emit(currentState), // 恢复之前的状态
    );
  }

  Future<void> _onProfileUpdateRequested(
    _ProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());

    final result = await _updateProfileUseCase(
      username: event.username,
      avatarUrl: event.avatarUrl,
      bio: event.bio,
    );

    result.fold(
      (failure) => emit(AuthState.error(_mapFailureToMessage(failure))),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  String _mapFailureToMessage(dynamic failure) {
    return failure.when(
      invalidCredentials: () => '邮箱或密码错误',
      emailAlreadyInUse: () => '该邮箱已被注册',
      weakPassword: () => '密码强度不足',
      userNotFound: () => '用户不存在',
      emailNotVerified: () => '邮箱未验证',
      networkError: () => '网络连接失败',
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
