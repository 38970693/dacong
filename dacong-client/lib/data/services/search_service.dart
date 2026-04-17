import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:injectable/injectable.dart';

/// Supabase Edge Function 搜索服务
@lazySingleton
class SearchService {
  final SupabaseClient _client;

  SearchService(this._client);

  /// 全文搜索内容
  ///
  /// 使用 PostgreSQL 的全文搜索功能
  /// 支持中英文搜索、筛选、排序
  Future<List<Map<String, dynamic>>> searchContent({
    required String query,
    String? scenario,
    bool? isFree,
    bool? availableInChina,
    String sortBy = 'relevance',
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // 构建查询（使用动态类型避免类型错误）
      dynamic builder = _client
          .from('published_content')
          .select('*')
          .or(
            'title_zh.ilike.%$query%,'
            'summary_zh.ilike.%$query%,'
            'title_en.ilike.%$query%,'
            'summary_en.ilike.%$query%',
          );

      // 场景筛选
      if (scenario != null) {
        builder = builder.eq('scenario', scenario);
      }

      // 排序
      switch (sortBy) {
        case 'rating':
          // 按有用率排序
          builder = builder.order('helpful_count', ascending: false);
          break;
        case 'viewCount':
          // 按浏览量排序
          builder = builder.order('view_count', ascending: false);
          break;
        case 'relevance':
        default:
          // 按相关度排序（默认按发布时间）
          builder = builder.order('published_at', ascending: false);
          break;
      }

      // 分页
      final response = await builder.range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('搜索失败: $e');
    }
  }

  /// 获取搜索建议
  ///
  /// 基于热门搜索和用户历史
  Future<List<String>> getSearchSuggestions({
    String? prefix,
    int limit = 10,
  }) async {
    try {
      // 这里简化处理，返回热门搜索
      // 实际应该从数据库统计热门搜索词
      final suggestions = [
        'Claude',
        'Cursor',
        'DeepSeek',
        'ChatGPT',
        'Midjourney',
        'Stable Diffusion',
        'GitHub Copilot',
        'Gemini',
        'Llama',
        'Mistral',
      ];

      if (prefix != null && prefix.isNotEmpty) {
        return suggestions
            .where((s) => s.toLowerCase().contains(prefix.toLowerCase()))
            .take(limit)
            .toList();
      }

      return suggestions.take(limit).toList();
    } catch (e) {
      return [];
    }
  }
}
