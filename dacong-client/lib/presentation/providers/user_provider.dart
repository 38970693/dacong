// 用户 & 认证 Provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/user_repository.dart';

// Repository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository.instance;
});

// ── 认证状态 ─────────────────────────────────

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(userRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => null,
  );
});

// ── 当前用户 Profile ─────────────────────────────────

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  return ref.read(userRepositoryProvider).getCurrentProfile();
});

// ── 其他用户 Profile ─────────────────────────────────

final profileProvider =
    FutureProvider.family<UserProfile?, String>((ref, userId) async {
  return ref.read(userRepositoryProvider).getProfile(userId);
});

// ── 登录 / 注册 ─────────────────────────────────

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final UserRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signInWithEmail(email, password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUpWithEmail(String email, String password, String username) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signUpWithEmail(email, password, username);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(userRepositoryProvider));
});

// ── Profile 更新 ─────────────────────────────────

class ProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final UserRepository _repo;

  ProfileNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> updateProfile({
    String? username,
    String? avatarUrl,
    String? bio,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateProfile(
        username: username,
        avatarUrl: avatarUrl,
        bio: bio,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final profileUpdateProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<void>>((ref) {
  return ProfileNotifier(ref.watch(userRepositoryProvider));
});
