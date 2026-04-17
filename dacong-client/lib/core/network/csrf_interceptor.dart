import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CSRF Token 拦截器
///
/// 功能：
/// - 从 Cookie 读取 CSRF Token
/// - 在请求头中添加 X-CSRF-Token
/// - 处理 Token 过期
/// - 自动刷新 Token
class CsrfInterceptor extends Interceptor {
  final String _baseUrl;
  final SharedPreferences _prefs;

  static const String _csrfTokenKey = 'csrf_token';
  static const String _csrfTokenExpiryKey = 'csrf_token_expiry';
  static const int _tokenExpirySeconds = 3600; // 1 小时

  CsrfInterceptor({
    required String baseUrl,
    required SharedPreferences prefs,
  })  : _baseUrl = baseUrl,
        _prefs = prefs;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 只对状态变更方法添加 CSRF Token
    if (_isStateMutatingMethod(options.method)) {
      try {
        final token = await _getValidToken();
        if (token != null) {
          options.headers['x-csrf-token'] = token;
        }
      } catch (e) {
        // Token 获取失败，继续请求（让服务端返回 403）
        print('Failed to get CSRF token: $e');
      }
    }

    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 如果是 CSRF Token 错误（403），尝试刷新 Token 并重试
    if (err.response?.statusCode == 403 &&
        _isCsrfError(err.response?.data)) {
      try {
        // 刷新 Token
        await _refreshToken();

        // 重试原请求
        final options = err.requestOptions;
        final token = await _getValidToken();
        if (token != null) {
          options.headers['x-csrf-token'] = token;
        }

        final dio = Dio();
        final response = await dio.fetch(options);
        handler.resolve(response);
        return;
      } catch (e) {
        // 刷新失败，返回原错误
        print('Failed to refresh CSRF token: $e');
      }
    }

    handler.next(err);
  }

  /// 判断是否是状态变更方法
  bool _isStateMutatingMethod(String method) {
    final upperMethod = method.toUpperCase();
    return ['POST', 'PUT', 'PATCH', 'DELETE'].contains(upperMethod);
  }

  /// 判断是否是 CSRF 错误
  bool _isCsrfError(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final error = responseData['error'] as String?;
      return error != null &&
          (error.contains('CSRF') || error.contains('csrf'));
    }
    return false;
  }

  /// 获取有效的 Token
  Future<String?> _getValidToken() async {
    final token = _prefs.getString(_csrfTokenKey);
    final expiryStr = _prefs.getString(_csrfTokenExpiryKey);

    if (token == null || expiryStr == null) {
      // Token 不存在，获取新 Token
      return await _refreshToken();
    }

    final expiry = DateTime.parse(expiryStr);
    final now = DateTime.now();

    // 如果 Token 即将过期（剩余时间 < 5 分钟），提前刷新
    if (expiry.difference(now).inMinutes < 5) {
      return await _refreshToken();
    }

    return token;
  }

  /// 刷新 Token
  Future<String?> _refreshToken() async {
    try {
      final dio = Dio();
      final response = await dio.get<Map<String, dynamic>>(
        '$_baseUrl/get-csrf-token',
      );

      if (response.statusCode == 200 && response.data != null) {
        final token = response.data!['token'] as String?;
        final expiresIn = response.data!['expiresIn'] as int? ?? _tokenExpirySeconds;

        if (token != null) {
          // 保存 Token 和过期时间
          await _prefs.setString(_csrfTokenKey, token);
          final expiry = DateTime.now().add(Duration(seconds: expiresIn));
          await _prefs.setString(_csrfTokenExpiryKey, expiry.toIso8601String());

          return token;
        }
      }

      return null;
    } catch (e) {
      print('Failed to refresh CSRF token: $e');
      return null;
    }
  }

  /// 清除 Token（用于登出）
  Future<void> clearToken() async {
    await _prefs.remove(_csrfTokenKey);
    await _prefs.remove(_csrfTokenExpiryKey);
  }
}
