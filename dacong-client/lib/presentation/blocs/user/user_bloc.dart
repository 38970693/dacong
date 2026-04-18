import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/user/get_current_user.dart';
import '../../../domain/usecases/user/get_user_preferences.dart';
import '../../../domain/usecases/user/manage_favorites.dart' as favorites_usecases;
import '../../../domain/usecases/user/update_user_preferences.dart';
import '../../../domain/usecases/user/update_user_profile.dart';
import '../../../domain/usecases/user/manage_history.dart' as history_usecases;
import 'user_event.dart';
import 'user_state.dart';

/// 用户 BLoC
@injectable
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetCurrentUser _getCurrentUser;
  final UpdateUserProfile _updateUserProfile;
  final GetUserPreferences _getUserPreferences;
  final UpdateUserPreferences _updateUserPreferences;
  final favorites_usecases.GetFavorites _getFavorites;
  final favorites_usecases.AddFavorite _addFavorite;
  final favorites_usecases.RemoveFavorite _removeFavorite;
  final favorites_usecases.IsFavorite _isFavorite;
  final history_usecases.GetHistory _getHistory;
  final history_usecases.AddHistory _addHistory;
  final history_usecases.ClearHistory _clearHistory;

  UserBloc(
    this._getCurrentUser,
    this._updateUserProfile,
    this._getUserPreferences,
    this._updateUserPreferences,
    this._getFavorites,
    this._addFavorite,
    this._removeFavorite,
    this._isFavorite,
    this._getHistory,
    this._addHistory,
    this._clearHistory,
  ) : super(UserState.initial()) {
    on<LoadUser>(_onLoadUser);
    on<UpdateProfile>(_onUpdateProfile);
    on<ToggleLanguage>(_onToggleLanguage);
    on<ToggleTheme>(_onToggleTheme);
    on<ToggleNotifications>(_onToggleNotifications);
    on<ToggleWeeklyReport>(_onToggleWeeklyReport);
    on<ToggleToolUpdate>(_onToggleToolUpdate);
    on<AddFavorite>(_onAddFavorite);
    on<RemoveFavorite>(_onRemoveFavorite);
    on<LoadFavorites>(_onLoadFavorites);
    on<AddHistory>(_onAddHistory);
    on<LoadHistory>(_onLoadHistory);
    on<ClearHistory>(_onClearHistory);
  }

  Future<void> _onLoadUser(LoadUser event, Emitter<UserState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    final userResult = await _getCurrentUser();
    final preferencesResult = await _getUserPreferences();

    userResult.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure.message)),
      (user) {
        preferencesResult.fold(
          (failure) => emit(state.copyWith(
            isLoading: false,
            user: user,
            error: failure.message,
          )),
          (preferences) => emit(state.copyWith(
            isLoading: false,
            user: user,
            preferences: preferences,
          )),
        );
      },
    );
  }

  Future<void> _onUpdateProfile(UpdateProfile event, Emitter<UserState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    final result = await _updateUserProfile(
      username: event.username,
      avatarUrl: event.avatarUrl,
      bio: event.bio,
    );

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure.message)),
      (user) => emit(state.copyWith(isLoading: false, user: user)),
    );
  }

  Future<void> _onToggleLanguage(ToggleLanguage event, Emitter<UserState> emit) async {
    if (state.preferences == null) return;

    final newPreferences = state.preferences!.copyWith(language: event.language);
    final result = await _updateUserPreferences(newPreferences);

    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) => emit(state.copyWith(preferences: newPreferences)),
    );
  }

  Future<void> _onToggleTheme(ToggleTheme event, Emitter<UserState> emit) async {
    if (state.preferences == null) return;

    final newPreferences = state.preferences!.copyWith(theme: event.theme);
    final result = await _updateUserPreferences(newPreferences);

    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) => emit(state.copyWith(preferences: newPreferences)),
    );
  }

  Future<void> _onToggleNotifications(ToggleNotifications event, Emitter<UserState> emit) async {
    if (state.preferences == null) return;

    final newPreferences = state.preferences!.copyWith(notificationsEnabled: event.enabled);
    final result = await _updateUserPreferences(newPreferences);

    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) => emit(state.copyWith(preferences: newPreferences)),
    );
  }

  Future<void> _onToggleWeeklyReport(ToggleWeeklyReport event, Emitter<UserState> emit) async {
    if (state.preferences == null) return;

    final newPreferences = state.preferences!.copyWith(weeklyReportEnabled: event.enabled);
    final result = await _updateUserPreferences(newPreferences);

    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) => emit(state.copyWith(preferences: newPreferences)),
    );
  }

  Future<void> _onToggleToolUpdate(ToggleToolUpdate event, Emitter<UserState> emit) async {
    if (state.preferences == null) return;

    final newPreferences = state.preferences!.copyWith(toolUpdateEnabled: event.enabled);
    final result = await _updateUserPreferences(newPreferences);

    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) => emit(state.copyWith(preferences: newPreferences)),
    );
  }

  Future<void> _onAddFavorite(AddFavorite event, Emitter<UserState> emit) async {
    final result = await _addFavorite(event.contentId);

    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {
        final newFavorites = [...state.favorites, event.contentId];
        emit(state.copyWith(favorites: newFavorites));
      },
    );
  }

  Future<void> _onRemoveFavorite(RemoveFavorite event, Emitter<UserState> emit) async {
    final result = await _removeFavorite(event.contentId);

    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {
        final newFavorites = state.favorites.where((id) => id != event.contentId).toList();
        emit(state.copyWith(favorites: newFavorites));
      },
    );
  }

  Future<void> _onLoadFavorites(LoadFavorites event, Emitter<UserState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    final result = await _getFavorites();

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure.message)),
      (favorites) => emit(state.copyWith(isLoading: false, favorites: favorites)),
    );
  }

  Future<void> _onAddHistory(AddHistory event, Emitter<UserState> emit) async {
    final result = await _addHistory(event.item);

    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) {
        final newHistory = [event.item, ...state.history];
        emit(state.copyWith(history: newHistory));
      },
    );
  }

  Future<void> _onLoadHistory(LoadHistory event, Emitter<UserState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));

    final result = await _getHistory();

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure.message)),
      (history) => emit(state.copyWith(isLoading: false, history: history)),
    );
  }

  Future<void> _onClearHistory(ClearHistory event, Emitter<UserState> emit) async {
    final result = await _clearHistory();

    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) => emit(state.copyWith(history: [])),
    );
  }
}
