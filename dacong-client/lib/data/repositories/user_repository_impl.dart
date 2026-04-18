import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/favorite_content.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../datasources/local_data_source.dart';
import '../datasources/favorites_remote_data_source.dart';

/// 用户仓储实现
@LazySingleton(as: IUserRepository)
class UserRepositoryImpl implements IUserRepository {
  final SupabaseClient _supabaseClient;
  final LocalDataSource _localDataSource;
  final FavoritesRemoteDataSource _favoritesRemoteDataSource;

  UserRepositoryImpl(
    this._supabaseClient,
    this._localDataSource,
    this._favoritesRemoteDataSource,
  );

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final authUser = _supabaseClient.auth.currentUser;
      if (authUser == null) {
        return const Left(ServerFailure('用户未登录'));
      }

      // 尝试从缓存获取
      final cached = await _localDataSource.getCachedUser();
      if (cached != null) {
        return Right(_userFromJson(cached));
      }

      // 从服务器获取
      final response = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (response == null) {
        return const Left(ServerFailure('用户信息不存在'));
      }

      // 缓存用户信息
      await _localDataSource.cacheUser(response);

      return Right(_userFromJson(response));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? username,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final authUser = _supabaseClient.auth.currentUser;
      if (authUser == null) {
        return Left(ServerFailure('用户未登录'));
      }

      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;
      if (bio != null) data['bio'] = bio;
      data['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabaseClient
          .from('profiles')
          .update(data)
          .eq('id', authUser.id)
          .select()
          .single();

      // 更新缓存
      await _localDataSource.cacheUser(response);

      return Right(_userFromJson(response));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserPreferences>> getUserPreferences() async {
    try {
      final language = await _localDataSource.getLanguage();
      final theme = await _localDataSource.getTheme();
      final notificationsEnabled = await _localDataSource.getNotificationsEnabled();
      final weeklyReportEnabled = await _localDataSource.getWeeklyReportEnabled();
      final toolUpdateEnabled = await _localDataSource.getToolUpdateEnabled();

      return Right(UserPreferences(
        language: language,
        theme: theme,
        notificationsEnabled: notificationsEnabled,
        weeklyReportEnabled: weeklyReportEnabled,
        toolUpdateEnabled: toolUpdateEnabled,
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateUserPreferences(UserPreferences preferences) async {
    try {
      await _localDataSource.saveLanguage(preferences.language);
      await _localDataSource.saveTheme(preferences.theme);
      await _localDataSource.saveNotificationsEnabled(preferences.notificationsEnabled);
      await _localDataSource.saveWeeklyReportEnabled(preferences.weeklyReportEnabled);
      await _localDataSource.saveToolUpdateEnabled(preferences.toolUpdateEnabled);

      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getFavorites() async {
    try {
      final favorites = await _favoritesRemoteDataSource.getFavorites();
      final contentIds = favorites.map((f) => f['content_id'] as String).toList();

      // 同步到本地缓存
      await _localDataSource.clearFavorites();
      for (final id in contentIds) {
        await _localDataSource.addFavorite(id);
      }

      return Right(contentIds);
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      // 如果网络请求失败，尝试从本地缓存获取
      try {
        final cachedFavorites = await _localDataSource.getFavoriteContentIds();
        return Right(cachedFavorites);
      } catch (_) {
        return Left(ServerFailure(e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, List<FavoriteContent>>> getFavoritesWithDetails({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final favorites = await _favoritesRemoteDataSource.getFavorites(
        page: page,
        limit: limit,
      );

      final favoriteContents = favorites.map((json) {
        return FavoriteContent(
          favoriteId: json['favorite_id'] as String,
          contentId: json['content_id'] as String,
          contentType: json['content_type'] as String,
          title: json['title'] as String,
          summary: json['summary'] as String?,
          scenario: json['scenario'] as String?,
          viewCount: json['view_count'] as int? ?? 0,
          helpfulCount: json['helpful_count'] as int? ?? 0,
          shareCount: json['share_count'] as int? ?? 0,
          publishedAt: DateTime.parse(json['published_at'] as String),
          favoritedAt: DateTime.parse(json['favorited_at'] as String),
        );
      }).toList();

      return Right(favoriteContents);
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addFavorite(String contentId) async {
    try {
      final isFavorited = await _favoritesRemoteDataSource.toggleFavorite(contentId);

      if (isFavorited) {
        // 同步到本地缓存
        await _localDataSource.addFavorite(contentId);
      }

      return const Right(unit);
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeFavorite(String contentId) async {
    try {
      final isFavorited = await _favoritesRemoteDataSource.toggleFavorite(contentId);

      if (!isFavorited) {
        // 同步到本地缓存
        await _localDataSource.removeFavorite(contentId);
      }

      return const Right(unit);
    } on AuthException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isFavorite(String contentId) async {
    try {
      final isFav = await _favoritesRemoteDataSource.isFavorite(contentId);
      return Right(isFav);
    } catch (e) {
      // 如果网络请求失败，尝试从本地缓存获取
      try {
        final cachedIsFav = await _localDataSource.isFavorite(contentId);
        return Right(cachedIsFav);
      } catch (_) {
        return Left(ServerFailure(e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, List<HistoryItem>>> getHistory({int limit = 50}) async {
    try {
      final history = await _localDataSource.getHistory();
      final items = history.map((json) => _historyItemFromJson(json)).toList();

      // 限制数量
      if (items.length > limit) {
        return Right(items.sublist(0, limit));
      }

      return Right(items);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addHistory(HistoryItem item) async {
    try {
      final json = _historyItemToJson(item);
      await _localDataSource.addHistory(json);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearHistory() async {
    try {
      await _localDataSource.clearHistory();
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // Helper methods
  User _userFromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      language: json['language'] as String? ?? 'zh',
      theme: json['theme'] as String? ?? 'system',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  HistoryItem _historyItemFromJson(Map<String, dynamic> json) {
    return HistoryItem(
      contentId: json['contentId'] as String,
      contentType: json['contentType'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      imageUrl: json['imageUrl'] as String?,
      viewedAt: DateTime.parse(json['viewedAt'] as String),
    );
  }

  Map<String, dynamic> _historyItemToJson(HistoryItem item) {
    return {
      'contentId': item.contentId,
      'contentType': item.contentType,
      'title': item.title,
      'summary': item.summary,
      'imageUrl': item.imageUrl,
      'viewedAt': item.viewedAt.toIso8601String(),
    };
  }
}
