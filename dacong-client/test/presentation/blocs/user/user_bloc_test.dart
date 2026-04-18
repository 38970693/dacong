import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dacong_client/core/error/failures.dart';
import 'package:dacong_client/domain/entities/user.dart';
import 'package:dacong_client/domain/usecases/user/manage_history.dart' as history_usecases;
import 'package:dacong_client/domain/usecases/user/get_current_user.dart';
import 'package:dacong_client/domain/usecases/user/get_user_preferences.dart';
import 'package:dacong_client/domain/usecases/user/manage_favorites.dart' as favorite_usecases;
import 'package:dacong_client/domain/usecases/user/update_user_preferences.dart';
import 'package:dacong_client/domain/usecases/user/update_user_profile.dart';
import 'package:dacong_client/presentation/blocs/user/user_bloc.dart';
import 'package:dacong_client/presentation/blocs/user/user_event.dart';
import 'package:dacong_client/presentation/blocs/user/user_state.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}
class MockUpdateUserProfile extends Mock implements UpdateUserProfile {}
class MockGetUserPreferences extends Mock implements GetUserPreferences {}
class MockUpdateUserPreferences extends Mock implements UpdateUserPreferences {}
class MockGetFavorites extends Mock implements favorite_usecases.GetFavorites {}
class MockAddFavoriteUseCase extends Mock implements favorite_usecases.AddFavorite {}
class MockRemoveFavoriteUseCase extends Mock implements favorite_usecases.RemoveFavorite {}
class MockIsFavorite extends Mock implements favorite_usecases.IsFavorite {}
class MockGetHistory extends Mock implements history_usecases.GetHistory {}
class MockAddHistoryUseCase extends Mock implements history_usecases.AddHistory {}
class MockClearHistoryUseCase extends Mock implements history_usecases.ClearHistory {}

void main() {
  late UserBloc bloc;
  late MockGetCurrentUser mockGetCurrentUser;
  late MockUpdateUserProfile mockUpdateUserProfile;
  late MockGetUserPreferences mockGetUserPreferences;
  late MockUpdateUserPreferences mockUpdateUserPreferences;
  late MockGetFavorites mockGetFavorites;
  late MockAddFavoriteUseCase mockAddFavorite;
  late MockRemoveFavoriteUseCase mockRemoveFavorite;
  late MockIsFavorite mockIsFavorite;
  late MockGetHistory mockGetHistory;
  late MockAddHistoryUseCase mockAddHistory;
  late MockClearHistoryUseCase mockClearHistory;

  const tUser = User(
    id: '1',
    email: 'test@example.com',
    username: 'testuser',
  );

  const tPreferences = UserPreferences(
    language: 'zh',
    theme: 'system',
    notificationsEnabled: true,
  );

  final tHistoryItem = HistoryItem(
    contentId: 'content-1',
    contentType: 'recommendation',
    title: 'Test Content',
    viewedAt: DateTime.now(),
  );

  setUp(() {
    mockGetCurrentUser = MockGetCurrentUser();
    mockUpdateUserProfile = MockUpdateUserProfile();
    mockGetUserPreferences = MockGetUserPreferences();
    mockUpdateUserPreferences = MockUpdateUserPreferences();
    mockGetFavorites = MockGetFavorites();
    mockAddFavorite = MockAddFavoriteUseCase();
    mockRemoveFavorite = MockRemoveFavoriteUseCase();
    mockIsFavorite = MockIsFavorite();
    mockGetHistory = MockGetHistory();
    mockAddHistory = MockAddHistoryUseCase();
    mockClearHistory = MockClearHistoryUseCase();

    bloc = UserBloc(
      mockGetCurrentUser,
      mockUpdateUserProfile,
      mockGetUserPreferences,
      mockUpdateUserPreferences,
      mockGetFavorites,
      mockAddFavorite,
      mockRemoveFavorite,
      mockIsFavorite,
      mockGetHistory,
      mockAddHistory,
      mockClearHistory,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('UserBloc', () {
    test('initial state should be UserState.initial', () {
      expect(bloc.state, equals(UserState.initial()));
    });

    group('LoadUser', () {
      blocTest<UserBloc, UserState>(
        'emits user and preferences when both succeed',
        build: () {
          when(() => mockGetCurrentUser())
              .thenAnswer((_) async => const Right(tUser));
          when(() => mockGetUserPreferences())
              .thenAnswer((_) async => const Right(tPreferences));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadUser()),
        expect: () => [
          const UserState(isLoading: true),
          const UserState(
            isLoading: false,
            user: tUser,
            preferences: tPreferences,
          ),
        ],
        verify: (_) {
          verify(() => mockGetCurrentUser()).called(1);
          verify(() => mockGetUserPreferences()).called(1);
        },
      );

      blocTest<UserBloc, UserState>(
        'emits error when getting user fails',
        build: () {
          when(() => mockGetCurrentUser())
              .thenAnswer((_) async => const Left(ServerFailure('User not found')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadUser()),
        expect: () => [
          const UserState(isLoading: true),
          const UserState(isLoading: false, error: 'User not found'),
        ],
      );

      blocTest<UserBloc, UserState>(
        'emits user but error when preferences fail',
        build: () {
          when(() => mockGetCurrentUser())
              .thenAnswer((_) async => const Right(tUser));
          when(() => mockGetUserPreferences())
              .thenAnswer((_) async => const Left(ServerFailure('Preferences error')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadUser()),
        expect: () => [
          const UserState(isLoading: true),
          const UserState(
            isLoading: false,
            user: tUser,
            error: 'Preferences error',
          ),
        ],
      );
    });

    group('UpdateProfile', () {
      const tUpdatedUser = User(
        id: '1',
        email: 'test@example.com',
        username: 'newusername',
      );

      blocTest<UserBloc, UserState>(
        'emits updated user when profile update succeeds',
        build: () {
          when(() => mockUpdateUserProfile(
                username: 'newusername',
                avatarUrl: null,
                bio: null,
              )).thenAnswer((_) async => const Right(tUpdatedUser));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const UpdateProfile(username: 'newusername'),
        ),
        expect: () => [
          const UserState(isLoading: true),
          const UserState(isLoading: false, user: tUpdatedUser),
        ],
        verify: (_) {
          verify(() => mockUpdateUserProfile(
                username: 'newusername',
                avatarUrl: null,
                bio: null,
              )).called(1);
        },
      );

      blocTest<UserBloc, UserState>(
        'emits error when profile update fails',
        build: () {
          when(() => mockUpdateUserProfile(
                username: 'newusername',
                avatarUrl: null,
                bio: null,
              )).thenAnswer((_) async => const Left(ServerFailure('Update failed')));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const UpdateProfile(username: 'newusername'),
        ),
        expect: () => [
          const UserState(isLoading: true),
          const UserState(isLoading: false, error: 'Update failed'),
        ],
      );
    });

    group('ToggleLanguage', () {
      blocTest<UserBloc, UserState>(
        'updates language preference when successful',
        build: () {
          when(() => mockUpdateUserPreferences(any()))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        seed: () => const UserState(preferences: tPreferences),
        act: (bloc) => bloc.add(const ToggleLanguage('en')),
        expect: () => [
          const UserState(
            preferences: UserPreferences(
              language: 'en',
              theme: 'system',
              notificationsEnabled: true,
            ),
          ),
        ],
        verify: (_) {
          verify(() => mockUpdateUserPreferences(any())).called(1);
        },
      );

      blocTest<UserBloc, UserState>(
        'emits error when language update fails',
        build: () {
          when(() => mockUpdateUserPreferences(any()))
              .thenAnswer((_) async => const Left(ServerFailure('Update failed')));
          return bloc;
        },
        seed: () => const UserState(preferences: tPreferences),
        act: (bloc) => bloc.add(const ToggleLanguage('en')),
        expect: () => [
          const UserState(
            preferences: tPreferences,
            error: 'Update failed',
          ),
        ],
      );
    });

    group('ToggleTheme', () {
      blocTest<UserBloc, UserState>(
        'updates theme preference when successful',
        build: () {
          when(() => mockUpdateUserPreferences(any()))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        seed: () => const UserState(preferences: tPreferences),
        act: (bloc) => bloc.add(const ToggleTheme('dark')),
        expect: () => [
          const UserState(
            preferences: UserPreferences(
              language: 'zh',
              theme: 'dark',
              notificationsEnabled: true,
            ),
          ),
        ],
      );
    });

    group('ToggleNotifications', () {
      blocTest<UserBloc, UserState>(
        'updates notification preference when successful',
        build: () {
          when(() => mockUpdateUserPreferences(any()))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        seed: () => const UserState(preferences: tPreferences),
        act: (bloc) => bloc.add(const ToggleNotifications(false)),
        expect: () => [
          const UserState(
            preferences: UserPreferences(
              language: 'zh',
              theme: 'system',
              notificationsEnabled: false,
            ),
          ),
        ],
      );
    });

    group('Favorites', () {
      blocTest<UserBloc, UserState>(
        'adds favorite when successful',
        build: () {
          when(() => mockAddFavorite('content-1'))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        act: (bloc) => bloc.add(const AddFavorite('content-1')),
        expect: () => [
          const UserState(favorites: ['content-1']),
        ],
        verify: (_) {
          verify(() => mockAddFavorite('content-1')).called(1);
        },
      );

      blocTest<UserBloc, UserState>(
        'removes favorite when successful',
        build: () {
          when(() => mockRemoveFavorite('content-1'))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        seed: () => const UserState(favorites: ['content-1', 'content-2']),
        act: (bloc) => bloc.add(const RemoveFavorite('content-1')),
        expect: () => [
          const UserState(favorites: ['content-2']),
        ],
        verify: (_) {
          verify(() => mockRemoveFavorite('content-1')).called(1);
        },
      );

      blocTest<UserBloc, UserState>(
        'loads favorites when successful',
        build: () {
          when(() => mockGetFavorites())
              .thenAnswer((_) async => const Right(['content-1', 'content-2']));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadFavorites()),
        expect: () => [
          const UserState(favorites: ['content-1', 'content-2']),
        ],
        verify: (_) {
          verify(() => mockGetFavorites()).called(1);
        },
      );

      blocTest<UserBloc, UserState>(
        'emits error when adding favorite fails',
        build: () {
          when(() => mockAddFavorite('content-1'))
              .thenAnswer((_) async => const Left(ServerFailure('Add failed')));
          return bloc;
        },
        act: (bloc) => bloc.add(const AddFavorite('content-1')),
        expect: () => [
          const UserState(error: 'Add failed'),
        ],
      );
    });

    group('History', () {
      blocTest<UserBloc, UserState>(
        'adds history item when successful',
        build: () {
          when(() => mockAddHistory(any()))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        act: (bloc) => bloc.add(AddHistory(tHistoryItem)),
        expect: () => [
          UserState(history: [tHistoryItem]),
        ],
        verify: (_) {
          verify(() => mockAddHistory(any())).called(1);
        },
      );

      blocTest<UserBloc, UserState>(
        'loads history when successful',
        build: () {
          when(() => mockGetHistory(limit: any(named: 'limit')))
              .thenAnswer((_) async => Right([tHistoryItem]));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadHistory()),
        expect: () => [
          const UserState(isLoading: true),
          UserState(isLoading: false, history: [tHistoryItem]),
        ],
        verify: (_) {
          verify(() => mockGetHistory(limit: any(named: 'limit'))).called(1);
        },
      );

      blocTest<UserBloc, UserState>(
        'clears history when successful',
        build: () {
          when(() => mockClearHistory())
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        seed: () => UserState(history: [tHistoryItem]),
        act: (bloc) => bloc.add(const ClearHistory()),
        expect: () => [
          const UserState(history: []),
        ],
        verify: (_) {
          verify(() => mockClearHistory()).called(1);
        },
      );

      blocTest<UserBloc, UserState>(
        'emits error when loading history fails',
        build: () {
          when(() => mockGetHistory(limit: any(named: 'limit')))
              .thenAnswer((_) async => const Left(ServerFailure('Load failed')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadHistory()),
        expect: () => [
          const UserState(isLoading: true),
          const UserState(isLoading: false, error: 'Load failed'),
        ],
      );
    });
  });
}
