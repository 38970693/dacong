import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:injectable/injectable.dart';
import '../models/recommendation_model.dart';
import '../models/content_model.dart';
import '../../core/error/exceptions.dart';

/// 远程数据源（单一职责：与 Supabase 交互）
@lazySingleton
class RemoteDataSource {
  final SupabaseClient _client;

  RemoteDataSource(this._client);

  /// 获取场景推荐
  Future<List<RecommendationModel>> getRecommendationsByScenario(
    String scenario,
  ) async {
    try {
      final response = await _client
          .from('scenario_recommendations')
          .select('*')
          .eq('scenario', scenario)
          .order('rank', ascending: true);

      return (response as List)
          .map((json) => RecommendationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('获取推荐失败: $e');
    }
  }

  /// 获取内容详情
  Future<ContentModel> getContentById(String contentId) async {
    try {
      final response = await _client
          .from('published_content')
          .select('*')
          .eq('id', contentId)
          .single();

      return ContentModel.fromJson(response);
    } catch (e) {
      throw ServerException('获取内容详情失败: $e');
    }
  }

  /// 获取相关内容
  Future<List<ContentModel>> getRelatedContent(
    String contentId, {
    int limit = 3,
  }) async {
    try {
      final response = await _client
          .from('published_content')
          .select('*')
          .neq('id', contentId)
          .limit(limit);

      return (response as List)
          .map((json) => ContentModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('获取相关内容失败: $e');
    }
  }

  /// 搜索内容
  Future<List<ContentModel>> searchContent(
    String query, {
    int limit = 20,
    int offset = 0,
    String? scenario,
    bool? isFree,
    bool? availableInChina,
    String sortBy = 'relevance',
  }) async {
    try {
      // 构建查询参数
      final queryParams = <String, String>{
        'q': query,
        'limit': limit.toString(),
        'offset': offset.toString(),
        'sort_by': sortBy,
      };

      if (scenario != null) {
        queryParams['scenario'] = scenario;
      }
      if (isFree != null) {
        queryParams['is_free'] = isFree.toString();
      }
      if (availableInChina != null) {
        queryParams['available_in_china'] = availableInChina.toString();
      }

      // 调用 Edge Function
      final response = await _client.functions.invoke(
        'search-content',
        queryParameters: queryParams,
      );

      if (response.status != 200) {
        throw ServerException('搜索失败: ${response.status}');
      }

      final data = response.data as Map<String, dynamic>;
      final results = data['data'] as List;

      return results.map((json) => ContentModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerException('搜索失败: $e');
    }
  }

  /// 提交反馈
  Future<void> submitFeedback({
    required String contentId,
    required String userId,
    required String type,
    String? comment,
  }) async {
    try {
      await _client.from('user_feedback').insert({
        'content_id': contentId,
        'user_id': userId,
        'type': type,
        'comment': comment,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw ServerException('提交反馈失败: $e');
    }
  }

  /// 获取通知列表
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int pageSize = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'get-notifications',
        queryParameters: {
          'page': page.toString(),
          'pageSize': pageSize.toString(),
          'unreadOnly': unreadOnly.toString(),
        },
      );

      if (response.status != 200) {
        throw ServerException('获取通知失败: ${response.status}');
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw ServerException('获取通知失败: $e');
    }
  }

  /// 标记通知为已读
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final response = await _client.functions.invoke(
        'mark-notification-read',
        body: {'notificationId': notificationId},
      );

      if (response.status != 200) {
        throw ServerException('标记通知失败: ${response.status}');
      }
    } catch (e) {
      throw ServerException('标记通知失败: $e');
    }
  }

  /// 标记所有通知为已读
  Future<void> markAllNotificationsAsRead() async {
    try {
      final response = await _client.functions.invoke('mark-all-read');

      if (response.status != 200) {
        throw ServerException('标记所有通知失败: ${response.status}');
      }
    } catch (e) {
      throw ServerException('标记所有通知失败: $e');
    }
  }
}
