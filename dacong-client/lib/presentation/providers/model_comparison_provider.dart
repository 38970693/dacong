// 模型能力对比 Provider - Riverpod 状态管理
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/model_capability.dart';
import '../../data/repositories/model_comparison_repository.dart';

// Repository Provider
final modelComparisonRepositoryProvider =
    Provider<ModelComparisonRepository>((ref) {
  return ModelComparisonRepository.instance;
});

// ── 待对比模型选择 ──────────────────────────────

/// 横评表列数上限，超出后表格在窄屏上不可读
const kMaxCompareModels = 4;

class CompareSelectionNotifier extends StateNotifier<List<String>> {
  CompareSelectionNotifier() : super(const []);

  bool isSelected(String modelId) => state.contains(modelId);

  bool get isFull => state.length >= kMaxCompareModels;

  /// 选中/取消某模型，已达上限时返回 false
  bool toggle(String modelId) {
    if (state.contains(modelId)) {
      state = state.where((id) => id != modelId).toList();
      return true;
    }
    if (isFull) return false;
    state = [...state, modelId];
    return true;
  }

  /// 用给定 id 列表初始化（进入页面时带入的模型）
  void seed(List<String> modelIds) {
    if (modelIds.isEmpty) return;
    state = modelIds.take(kMaxCompareModels).toList();
  }

  void clear() => state = const [];
}

final compareSelectionProvider =
    StateNotifierProvider<CompareSelectionNotifier, List<String>>((ref) {
  return CompareSelectionNotifier();
});

// ── 对比数据 ──────────────────────────────

final modelComparisonProvider =
    FutureProvider<List<ModelCapability>>((ref) async {
  final ids = ref.watch(compareSelectionProvider);
  if (ids.isEmpty) return [];
  return ref.read(modelComparisonRepositoryProvider).getComparison(ids: ids);
});
