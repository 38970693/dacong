import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CSRF Token 服务（管理后台版本）
/// 负责获取、缓存和刷新 CSRF Token
class CsrfService {
  final SupabaseClient _supabase;

  static const String _csrfTokenKey = 'admin_csrf_token';
  static const String _csrfExpiryKey = 'admin_csrf_token_expiry';

  String? _cachedToken;
  DateTime? _tokenExpiry;

  CsrfService(this._supabase);

  /// 获取 CSRF Token（优先使用缓存）
  Future<String> getCsrfToken() async {
    // 检查缓存的 Token 是否有效
    if (_cachedToken != null && _tokenExpiry != null) {
      if (DateTime.now().isBefore(_tokenExpiry!)) {
        return _cachedToken!;
      }
    }

    // 从持久化存储中恢复
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_csrfTokenKey);
    final storedExpiry = prefs.getInt(_csrfExpiryKey);

    if (storedToken != null && storedExpiry != null) {
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(storedExpiry);
      if (DateTime.now().isBefore(expiryDate)) {
        _cachedToken = storedToken;
        _tokenExpiry = expiryDate;
        return storedToken;
      }
    }

    // Token 过期或不存在，获取新的
    return await refreshToken();
  }

  /// 刷新 CSRF Token
  Future<String> refreshToken() async {
    try {
      final session = _supabase.auth.currentSession;
      final headers = session != null
          ? {'Authorization': 'Bearer ${session.accessToken}'}
          : <String, String>{};

      final response = await _supabase.functions.invoke(
        'csrf-token',
        method: HttpMethod.get,
        headers: headers,
      );

      if (response.status == 200) {
        final data = response.data;
        final token = data['data']['csrf_token'] as String;
        final expiresIn = data['data']['expires_in'] as int;

        // 缓存 Token（提前 5 分钟过期以避免边界情况）
        _cachedToken = token;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 300));

        // 持久化存储
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_csrfTokenKey, token);
        await prefs.setInt(_csrfExpiryKey, _tokenExpiry!.millisecondsSinceEpoch);

        return token;
      } else {
        throw Exception('Failed to fetch CSRF token: ${response.status}');
      }
    } catch (e) {
      throw Exception('Failed to refresh CSRF token: $e');
    }
  }

  /// 清除 CSRF Token（用于登出）
  Future<void> clearToken() async {
    _cachedToken = null;
    _tokenExpiry = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_csrfTokenKey);
    await prefs.remove(_csrfExpiryKey);

    // 通知服务器清除 Token
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _supabase.functions.invoke(
          'csrf-token',
          method: HttpMethod.delete,
          headers: {'Authorization': 'Bearer ${session.accessToken}'},
        );
      }
    } catch (e) {
      // 忽略错误，本地已清除
    }
  }

  /// 检查 Token 是否即将过期（5 分钟内）
  bool isTokenExpiringSoon() {
    if (_tokenExpiry == null) return true;
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return _tokenExpiry!.isBefore(fiveMinutesFromNow);
  }
}
