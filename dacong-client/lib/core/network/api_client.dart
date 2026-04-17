import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../error/exceptions.dart';

/// HTTP 客户端（单一职责：处理网络请求）
@lazySingleton
class ApiClient {
  final Dio _dio;

  ApiClient(this._dio) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 添加通用请求头
          options.headers['Content-Type'] = 'application/json';
          return handler.next(options);
        },
        onError: (error, handler) {
          // 统一错误处理
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: const NetworkException('连接超时'),
              ),
            );
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('网络连接超时');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return const ServerException('资源不存在');
        } else if (statusCode == 401) {
          return const ServerException('未授权访问');
        } else if (statusCode != null && statusCode >= 500) {
          return const ServerException('服务器错误');
        }
        return ServerException(error.message ?? '请求失败');
      case DioExceptionType.cancel:
        return const NetworkException('请求已取消');
      case DioExceptionType.unknown:
        return const NetworkException('网络连接失败');
      default:
        return ServerException(error.message ?? '未知错误');
    }
  }
}
