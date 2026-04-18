import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dacong_client/domain/entities/user.dart';
import 'package:dacong_client/domain/entities/auth_session.dart';
import 'package:dacong_client/domain/usecases/auth/login_use_case.dart';
import 'package:dacong_client/domain/usecases/auth/register_use_case.dart';
import 'package:dacong_client/domain/usecases/auth/logout_use_case.dart';
import 'package:dacong_client/domain/usecases/auth/get_current_user_use_case.dart';
import 'package:dacong_client/domain/usecases/auth/update_profile_use_case.dart';
import 'package:dacong_client/domain/usecases/auth/send_password_reset_email_use_case.dart';
import 'package:dacong_client/domain/repositories/i_auth_repository.dart';
import 'package:dacong_client/core/error/auth_failure.dart';
import 'package:dacong_client/presentation/blocs/auth/auth_bloc.dart';
import 'package:dacong_client/presentation/blocs/auth/auth_event.dart';
import 'package:dacong_client/presentation/blocs/auth/auth_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}
class MockSendPasswordResetEmailUseCase extends Mock implements SendPasswordResetEmailUseCase {}
class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late AuthBloc bloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockUpdateProfileUseCase mockUpdateProfileUseCase;
  late MockSendPasswordResetEmailUseCase mockSendPasswordResetEmailUseCase;
  late MockAuthRepository mockAuthRepository;
  late StreamController<User?> authStateController;
  late AuthSession tSession;

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUsername = 'testuser';
  const tUser = User(
    id: '1',
    email: 'test@example.com',
    username: 'testuser',
  );

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockRegisterUseCase = MockRegisterUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockUpdateProfileUseCase = MockUpdateProfileUseCase();
    mockSendPasswordResetEmailUseCase = MockSendPasswordResetEmailUseCase();
    mockAuthRepository = MockAuthRepository();

    authStateController = StreamController<User?>.broadcast();
    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer((_) => authStateController.stream);

    tSession = AuthSession(
      user: tUser,
      accessToken: 'token',
      refreshToken: 'refresh_token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );

    bloc = AuthBloc(
      mockLoginUseCase,
      mockRegisterUseCase,
      mockLogoutUseCase,
      mockGetCurrentUserUseCase,
      mockUpdateProfileUseCase,
      mockSendPasswordResetEmailUseCase,
      mockAuthRepository,
    );
  });

  tearDown(() {
    authStateController.close();
    bloc.close();
  });

  group('AuthBloc', () {

    test('initial state should be AuthState.initial', () {
      expect(bloc.state, equals(const AuthState.initial()));
    });

    group('AuthCheckRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] when user is logged in',
        build: () {
          when(() => mockGetCurrentUserUseCase())
              .thenAnswer((_) async => const Right(tUser));
          return bloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.authCheckRequested()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.authenticated(tUser),
        ],
        verify: (_) {
          verify(() => mockGetCurrentUserUseCase()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, unauthenticated] when no user is logged in',
        build: () {
          when(() => mockGetCurrentUserUseCase())
              .thenAnswer((_) async => const Left(AuthFailure.userNotFound()));
          return bloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.authCheckRequested()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
      );
    });

    group('LoginRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] when login succeeds',
        build: () {
          when(() => mockLoginUseCase(email: tEmail, password: tPassword))
              .thenAnswer((_) async => Right(tSession));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const AuthEvent.loginRequested(email: tEmail, password: tPassword),
        ),
        expect: () => [
          const AuthState.loading(),
          const AuthState.authenticated(tUser),
        ],
        verify: (_) {
          verify(() => mockLoginUseCase(email: tEmail, password: tPassword))
              .called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] when login fails with invalid credentials',
        build: () {
          when(() => mockLoginUseCase(email: tEmail, password: tPassword))
              .thenAnswer((_) async => const Left(AuthFailure.invalidCredentials()));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const AuthEvent.loginRequested(email: tEmail, password: tPassword),
        ),
        expect: () => [
          const AuthState.loading(),
          const AuthState.error('邮箱或密码错误'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] when login fails with network error',
        build: () {
          when(() => mockLoginUseCase(email: tEmail, password: tPassword))
              .thenAnswer((_) async => const Left(AuthFailure.networkError()));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const AuthEvent.loginRequested(email: tEmail, password: tPassword),
        ),
        expect: () => [
          const AuthState.loading(),
          const AuthState.error('网络连接失败'),
        ],
      );
    });

    group('RegisterRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] when registration succeeds',
        build: () {
          when(() => mockRegisterUseCase(
                email: tEmail,
                password: tPassword,
                username: tUsername,
              )).thenAnswer((_) async => Right(tSession));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const AuthEvent.registerRequested(
            email: tEmail,
            password: tPassword,
            username: tUsername,
          ),
        ),
        expect: () => [
          const AuthState.loading(),
          const AuthState.authenticated(tUser),
        ],
        verify: (_) {
          verify(() => mockRegisterUseCase(
                email: tEmail,
                password: tPassword,
                username: tUsername,
              )).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] when email is already in use',
        build: () {
          when(() => mockRegisterUseCase(
                email: tEmail,
                password: tPassword,
                username: tUsername,
              )).thenAnswer((_) async => const Left(AuthFailure.emailAlreadyInUse()));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const AuthEvent.registerRequested(
            email: tEmail,
            password: tPassword,
            username: tUsername,
          ),
        ),
        expect: () => [
          const AuthState.loading(),
          const AuthState.error('该邮箱已被注册'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] when password is weak',
        build: () {
          when(() => mockRegisterUseCase(
                email: tEmail,
                password: tPassword,
                username: tUsername,
              )).thenAnswer((_) async => const Left(AuthFailure.weakPassword()));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const AuthEvent.registerRequested(
            email: tEmail,
            password: tPassword,
            username: tUsername,
          ),
        ),
        expect: () => [
          const AuthState.loading(),
          const AuthState.error('密码强度不足'),
        ],
      );
    });

    group('LogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [loading, unauthenticated] when logout succeeds',
        build: () {
          when(() => mockLogoutUseCase())
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.logoutRequested()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
        verify: (_) {
          verify(() => mockLogoutUseCase()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] when logout fails',
        build: () {
          when(() => mockLogoutUseCase())
              .thenAnswer((_) async => const Left(AuthFailure.serverError('Logout failed')));
          return bloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.logoutRequested()),
        expect: () => [
          const AuthState.loading(),
          const AuthState.error('服务器错误: Logout failed'),
        ],
      );
    });

    group('PasswordResetRequested', () {
      blocTest<AuthBloc, AuthState>(
        'restores previous state when password reset succeeds',
        build: () {
          when(() => mockSendPasswordResetEmailUseCase(tEmail))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        seed: () => const AuthState.unauthenticated(),
        act: (bloc) => bloc.add(const AuthEvent.passwordResetRequested(tEmail)),
        expect: () => [
          const AuthState.loading(),
          const AuthState.unauthenticated(),
        ],
        verify: (_) {
          verify(() => mockSendPasswordResetEmailUseCase(tEmail)).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] when password reset fails',
        build: () {
          when(() => mockSendPasswordResetEmailUseCase(tEmail))
              .thenAnswer((_) async => const Left(AuthFailure.userNotFound()));
          return bloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.passwordResetRequested(tEmail)),
        expect: () => [
          const AuthState.loading(),
          const AuthState.error('用户不存在'),
        ],
      );
    });

    group('ProfileUpdateRequested', () {
      const tUpdatedUser = User(
        id: '1',
        email: 'test@example.com',
        username: 'newusername',
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, authenticated] when profile update succeeds',
        build: () {
          when(() => mockUpdateProfileUseCase(
                username: 'newusername',
                avatarUrl: null,
                bio: null,
              )).thenAnswer((_) async => const Right(tUpdatedUser));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const AuthEvent.profileUpdateRequested(username: 'newusername'),
        ),
        expect: () => [
          const AuthState.loading(),
          const AuthState.authenticated(tUpdatedUser),
        ],
        verify: (_) {
          verify(() => mockUpdateProfileUseCase(
                username: 'newusername',
                avatarUrl: null,
                bio: null,
              )).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [loading, error] when profile update fails',
        build: () {
          when(() => mockUpdateProfileUseCase(
                username: 'newusername',
                avatarUrl: null,
                bio: null,
              )).thenAnswer((_) async => const Left(AuthFailure.serverError('Update failed')));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const AuthEvent.profileUpdateRequested(username: 'newusername'),
        ),
        expect: () => [
          const AuthState.loading(),
          const AuthState.error('服务器错误: Update failed'),
        ],
      );
    });

    group('Auth State Stream', () {
      test('emits authenticated when user logs in via stream', () async {
        expectLater(
          bloc.stream,
          emitsInOrder([
            const AuthState.authenticated(tUser),
          ]),
        );

        authStateController.add(tUser);
      });

      test('emits unauthenticated when user logs out via stream', () async {
        expectLater(
          bloc.stream,
          emitsInOrder([
            const AuthState.unauthenticated(),
          ]),
        );

        authStateController.add(null);
      });
    });
  });
}
