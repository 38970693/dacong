// AI 模型 Repository
// 职责：封装所有模型相关的数据访问（Supabase + 本地缓存）
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ai_model.dart';

class ModelsRepository {
  ModelsRepository._();
  static final _instance = ModelsRepository._();
  static ModelsRepository get instance => _instance;

  final _client = Supabase.instance.client;

  /// 获取综合排行榜
  Future<List<AIModel>> getRanking({
    int page = 0,
    int pageSize = 20,
    String? category,
  }) async {
    var query = _client
        .from('models')
        .select('*, model_ranks(rank_overall, rank_category, score, rank_updated_at)');

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    final response = await query
        .not('rank_overall', 'is', null)
        .order('rank_overall', ascending: true)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return (response as List<dynamic>)
        .map((e) => AIModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取分类排行榜
  Future<List<AIModel>> getCategoryRanking(String category, {int page = 0, int pageSize = 20}) async {
    final response = await _client
        .from('models')
        .select('*, model_ranks(rank_overall, rank_category, score, rank_updated_at)')
        .eq('category', category)
        .not('rank_category', 'is', null)
        .order('rank_category', ascending: true)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    return (response as List<dynamic>)
        .map((e) => AIModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 搜索模型
  Future<List<AIModel>> searchModels(String query, {int limit = 20}) async {
    final response = await _client
        .from('models')
        .select('*, model_ranks(rank_overall, score)')
        .or('name.ilike.%$query%,description.ilike.%$query%')
        .limit(limit);

    return (response as List<dynamic>)
        .map((e) => AIModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取模型详情
  Future<AIModel?> getModelById(String id) async {
    final response = await _client
        .from('models')
        .select('*, model_ranks(rank_overall, rank_category, score, rank_updated_at)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return AIModel.fromJson(response);
  }

  /// 获取模型原始指标历史
  Future<List<Map<String, dynamic>>> getModelMetricsHistory(
    String modelId, {
    int hours = 24,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(hours: hours));
    final response = await _client
        .from('model_raw_metrics')
        .select('*')
        .eq('model_id', modelId)
        .gte('fetched_at', cutoff.toIso8601String())
        .order('fetched_at', ascending: true);

    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// 获取所有分类（去重）
  Future<List<String>> getAllCategories() async {
    final response = await _client
        .from('models')
        .select('category')
        .not('category', 'is', null);

    final categories = (response as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['category'] as String)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }
}
