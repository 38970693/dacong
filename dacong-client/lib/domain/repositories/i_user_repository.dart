import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/user.dart';
import '../entities/favorite_content.dart';

/// 用户仓储接口
abstract class IUserRepository {
  /// 获取当前用户信息
  Future<Either<Failure, User>> getCurrentUser();

  /// 更新用户资料
  Future<Either<Failure, User>> updateProfile({
    String? username,
    String? avatarUrl,
    String? bio,
  });

  /// 获取用户偏好设置
  Future<Either<Failure, UserPreferences>> getUserPreferences();

  /// 更新用户偏好设置
  Future<Either<Failure, Unit>> updateUserPreferences(UserPreferences preferences);

  /// 获取收藏列表（仅ID）
  Future<Either<Failure, List<String>>> getFavorites();

  /// 获取收藏列表（完整内容）
  Future<Either<Failure, List<FavoriteContent>>> getFavoritesWithDetails({
    int page = 1,
    int limit = 20,
  });

  /// 添加收藏
  Future<Either<Failure, Unit>> addFavorite(String contentId);

  /// 移除收藏
  Future<Either<Failure, Unit>> removeFavorite(String contentId);

  /// 检查是否已收藏
  Future<Either<Failure, bool>> isFavorite(String contentId);

  /// 获取浏览历史
  Future<Either<Failure, List<HistoryItem>>> getHistory({int limit = 50});

  /// 添加浏览历史
  Future<Either<Failure, Unit>> addHistory(HistoryItem item);

  /// 清空浏览历史
  Future<Either<Failure, Unit>> clearHistory();
}
