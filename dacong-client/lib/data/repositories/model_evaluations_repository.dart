// 大模型评测成绩 Repository
// 职责：调用 get-model-evaluations Edge Function
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/model_evaluation.dart';

class ModelEvaluationsRepository {
  ModelEvaluationsRepository._();
  static final _instance = ModelEvaluationsRepository._();
  static ModelEvaluationsRepository get instance => _instance;

  final _client = Supabase.instance.client;

  /// 获取某模型的评测成绩（可按 benchmark / category 过滤）
  Future<List<ModelEvaluation>> getEvaluations({
    required String modelId,
    String? benchmark,
    String? category,
    int limit = 100,
  }) async {
    final queryParams = <String, String>{
      'model_id': modelId,
      'limit': limit.toString(),
    };
    if (benchmark != null && benchmark.isNotEmpty) {
      queryParams['benchmark'] = benchmark;
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }

    final response = await _client.functions.invoke(
      'get-model-evaluations',
      queryParameters: queryParams,
    );

    if (response.status != 200) {
      throw Exception('获取评测成绩失败: ${response.status}');
    }

    final body = response.data as Map<String, dynamic>;
    final results = body['data'] as List<dynamic>? ?? [];

    return results
        .map((e) => ModelEvaluation.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
