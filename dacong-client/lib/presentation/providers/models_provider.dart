// 排行榜 Provider - Riverpod 状态管理
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ai_model.dart';
import '../../data/repositories/models_repository.dart';

// Repository Provider
final modelsRepositoryProvider = Provider<ModelsRepository>((ref) {
  return ModelsRepository.instance;
});

// ── 综合榜 ──────────────────────────────────

class RankingState {
  final List<AIModel> models;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;

  const RankingState({
    this.models = const [],
    this.isLoading = false,
    this.error,
    this.page = 0,
    this.hasMore = true,
  });

  RankingState copyWith({
    List<AIModel>? models,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
  }) {
    return RankingState(
      models: models ?? this.models,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class RankingNotifier extends StateNotifier<RankingState> {
  final ModelsRepository _repo;

  RankingNotifier(this._repo) : super(const RankingState());

  Future<void> loadInitial({String? category}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final models = await _repo.getRanking(category: category);
      state = RankingState(
        models: models,
        isLoading: false,
        page: 0,
        hasMore: models.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({String? category}) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.page + 1;
      final more = await _repo.getRanking(page: nextPage, category: category);
      state = state.copyWith(
        models: [...state.models, ...more],
        isLoading: false,
        page: nextPage,
        hasMore: more.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh({String? category}) async {
    state = const RankingState();
    await loadInitial(category: category);
  }
}

final rankingProvider =
    StateNotifierProvider<RankingNotifier, RankingState>((ref) {
  return RankingNotifier(ref.watch(modelsRepositoryProvider));
});

// ── 搜索 ──────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<AIModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.length < 2) return [];
  return ref.read(modelsRepositoryProvider).searchModels(query);
});

// ── 模型详情 ──────────────────────────────────

final modelDetailProvider =
    FutureProvider.family<AIModel?, String>((ref, modelId) async {
  return ref.read(modelsRepositoryProvider).getModelById(modelId);
});

// ── 分类列表 ──────────────────────────────────

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  return ref.read(modelsRepositoryProvider).getAllCategories();
});

// ── 选中分类 ──────────────────────────────────

final selectedCategoryProvider = StateProvider<String?>((ref) => null);
