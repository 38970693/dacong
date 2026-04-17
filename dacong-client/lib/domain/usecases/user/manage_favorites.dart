import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../core/error/failures.dart';
import '../../repositories/i_user_repository.dart';

/// 获取收藏列表用例
@lazySingleton
class GetFavorites {
  final IUserRepository _repository;

  GetFavorites(this._repository);

  Future<Either<Failure, List<String>>> call() {
    return _repository.getFavorites();
  }
}

/// 添加收藏用例
@lazySingleton
class AddFavorite {
  final IUserRepository _repository;

  AddFavorite(this._repository);

  Future<Either<Failure, Unit>> call(String contentId) {
    return _repository.addFavorite(contentId);
  }
}

/// 移除收藏用例
@lazySingleton
class RemoveFavorite {
  final IUserRepository _repository;

  RemoveFavorite(this._repository);

  Future<Either<Failure, Unit>> call(String contentId) {
    return _repository.removeFavorite(contentId);
  }
}

/// 检查是否已收藏用例
@lazySingleton
class IsFavorite {
  final IUserRepository _repository;

  IsFavorite(this._repository);

  Future<Either<Failure, bool>> call(String contentId) {
    return _repository.isFavorite(contentId);
  }
}
