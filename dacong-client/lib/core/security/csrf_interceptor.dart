import 'package:dio/dio.dart';
import 'csrf_service.dart';

/// CSRF Token 拦截器
/// 自动在请求头中添加 CSRF Token
class CsrfInterceptor extends Interceptor {
  final CsrfService _csrfService;

  CsrfInterceptor(this._csrfService);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 只对状态变更方法添加 CSRF Token
    if (_shouldAddCsrfToken(options.method)) {
      try {
        // 检查 Token 是否即将过期，提前刷新
        if (_csrfService.isTokenExpiringSoon()) {
          await _csrfService.refreshToken();
        }

        final token = await _csrfService.getCsrfToken();
        options.headers['X-CSRF-Token'] = token;
      } catch (e) {
        // Token 获取失败，拒绝请求
        return handler.reject(
          DioException(
            requestOptions: options,
            error: 'Failed to get CSRF token: $e',
            type: DioExceptionType.unknown,
          ),
        );
      }
    }

    return handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 如果是 CSRF Token 错误（403），尝试刷新 Token 并重试
    if (err.response?.statusCode == 403) {
      final errorMessage = err.response?.data?['error'] as String?;

      if (errorMessage != null &&
          (errorMessage.contains('CSRF') ||
           errorMessage.contains('csrf'))) {
        try {
          // 刷新 Token
          await _csrfService.refreshToken();

          // 重试原始请求
          final options = err.requestOptions;
          final token = await _csrfService.getCsrfToken();
          options.headers['X-CSRF-Token'] = token;

          final response = await Dio().fetch(options);
          return handler.resolve(response);
        } catch (e) {
          // 刷新失败，返回原始错误
          return handler.next(err);
        }
      }
    }

    return handler.next(err);
  }

  /// 判断是否需要添加 CSRF Token
  bool _shouldAddCsrfToken(String method) {
    final upperMethod = method.toUpperCase();
    return ['POST', 'PUT', 'PATCH', 'DELETE'].contains(upperMethod);
  }
}
