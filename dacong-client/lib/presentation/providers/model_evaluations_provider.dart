// 模型评测成绩 Provider - Riverpod 状态管理
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/model_evaluation.dart';
import '../../data/repositories/model_evaluations_repository.dart';

// Repository Provider
final modelEvaluationsRepositoryProvider =
    Provider<ModelEvaluationsRepository>((ref) {
  return ModelEvaluationsRepository.instance;
});

// 按 modelId 拉取评测成绩
final modelEvaluationsProvider =
    FutureProvider.family<List<ModelEvaluation>, String>((ref, modelId) async {
  return ref
      .read(modelEvaluationsRepositoryProvider)
      .getEvaluations(modelId: modelId);
});
