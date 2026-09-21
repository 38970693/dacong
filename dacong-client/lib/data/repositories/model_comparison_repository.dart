// 大模型能力对比 Repository
// 职责：调用 get-model-comparison Edge Function
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/model_capability.dart';

class ModelComparisonRepository {
  ModelComparisonRepository._();
  static final _instance = ModelComparisonRepository._();
  static ModelComparisonRepository get instance => _instance;

  final _client = Supabase.instance.client;

  /// 获取多个模型的能力对比数据（ids 与 category 至少提供一个）
  Future<List<ModelCapability>> getComparison({
    List<String> ids = const [],
    String? category,
    int limit = 10,
  }) async {
    if (ids.isEmpty && (category == null || category.isEmpty)) {
      return [];
    }

    final queryParams = <String, String>{'limit': limit.toString()};
    if (ids.isNotEmpty) {
      queryParams['ids'] = ids.join(',');
    } else {
      queryParams['category'] = category!;
    }

    final response = await _client.functions.invoke(
      'get-model-comparison',
      queryParameters: queryParams,
    );

    if (response.status != 200) {
      throw Exception('获取能力对比失败: ${response.status}');
    }

    final body = response.data as Map<String, dynamic>;
    final results = body['data'] as List<dynamic>? ?? [];

    return results
        .map((e) => ModelCapability.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
