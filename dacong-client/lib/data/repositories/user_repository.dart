// 用户 Repository
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';

class UserRepository {
  UserRepository._();
  static final _instance = UserRepository._();
  static UserRepository get instance => _instance;

  final _client = Supabase.instance.client;

  /// 当前登录用户
  User? get currentUser => _client.auth.currentUser;

  /// 获取当前用户 Profile
  Future<UserProfile?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  /// 获取其他用户 Profile
  Future<UserProfile?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  /// 更新 Profile
  Future<void> updateProfile({
    String? username,
    String? avatarUrl,
    String? bio,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final data = <String, dynamic>{};
    if (username != null) data['username'] = username;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (bio != null) data['bio'] = bio;

    await _client.from('profiles').update(data).eq('id', user.id);
  }

  /// 邮箱登录
  Future<AuthResponse> signInWithEmail(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// 注册
  Future<AuthResponse> signUpWithEmail(String email, String password, String username) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
  }

  /// 退出登录
  Future<void> signOut() => _client.auth.signOut();

  /// 监听登录状态变化
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
