import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 收藏功能远程数据源
@injectable
class FavoritesRemoteDataSource {
  final SupabaseClient _client;

  FavoritesRemoteDataSource(this._client);

  /// 切换收藏状态
  Future<bool> toggleFavorite(String contentId) async {
    final response = await _client.functions.invoke(
      'toggle-favorite',
      body: {'content_id': contentId},
    );

    if (response.status != 200) {
      throw Exception('Failed to toggle favorite');
    }

    final data = response.data as Map<String, dynamic>;
    return data['data']['is_favorited'] as bool;
  }

  /// 获取收藏列表
  Future<List<Map<String, dynamic>>> getFavorites({
    int page = 1,
    int limit = 20,
    String language = 'zh',
  }) async {
    final response = await _client.functions.invoke(
      'get-favorites',
      method: HttpMethod.get,
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'language': language,
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to fetch favorites');
    }

    final data = response.data as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['data'] as List);
  }

  /// 检查是否已收藏（通过查询收藏列表）
  Future<bool> isFavorite(String contentId) async {
    try {
      final favorites = await _client
          .from('favorites')
          .select('id')
          .eq('content_id', contentId)
          .maybeSingle();

      return favorites != null;
    } catch (e) {
      return false;
    }
  }
}
