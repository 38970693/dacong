/// 服务器异常
class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

/// 网络异常
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

/// 缓存异常
class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

/// 验证异常
class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
}
