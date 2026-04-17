import 'package:equatable/equatable.dart';

/// 基础失败类
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// 服务器错误
class ServerFailure extends Failure {
  const ServerFailure([String message = '服务器错误']) : super(message);
}

/// 网络错误
class NetworkFailure extends Failure {
  const NetworkFailure([String message = '网络连接失败']) : super(message);
}

/// 缓存错误
class CacheFailure extends Failure {
  const CacheFailure([String message = '缓存错误']) : super(message);
}

/// 验证错误
class ValidationFailure extends Failure {
  const ValidationFailure([String message = '数据验证失败']) : super(message);
}

/// 未找到错误
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = '未找到资源']) : super(message);
}

/// 未授权错误
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String message = '未授权访问']) : super(message);
}
