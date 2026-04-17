// 快讯 Provider - Riverpod 状态管理
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/hot_news_model.dart';
import '../../data/repositories/news_repository.dart';

// Repository Provider
final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepository.instance;
});

// ── 快讯流 ──────────────────────────────────

class NewsState {
  final List<HotNews> news;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;

  const NewsState({
    this.news = const [],
    this.isLoading = false,
    this.error,
    this.page = 0,
    this.hasMore = true,
  });

  NewsState copyWith({
    List<HotNews>? news,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
  }) {
    return NewsState(
      news: news ?? this.news,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class NewsNotifier extends StateNotifier<NewsState> {
  final NewsRepository _repo;

  NewsNotifier(this._repo) : super(const NewsState());

  Future<void> loadInitial({String? source}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final news = await _repo.getHotNews(source: source);
      state = NewsState(
        news: news,
        isLoading: false,
        page: 0,
        hasMore: news.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({String? source}) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.page + 1;
      final more = await _repo.getHotNews(page: nextPage, source: source);
      state = state.copyWith(
        news: [...state.news, ...more],
        isLoading: false,
        page: nextPage,
        hasMore: more.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh({String? source}) async {
    state = const NewsState();
    await loadInitial(source: source);
  }
}

final newsProvider = StateNotifierProvider<NewsNotifier, NewsState>((ref) {
  return NewsNotifier(ref.watch(newsRepositoryProvider));
});

// ── 热搜词 ──────────────────────────────────

final trendingKeywordsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(newsRepositoryProvider).getTrendingKeywords();
});

// ── 新闻搜索 ──────────────────────────────────

final newsSearchQueryProvider = StateProvider<String>((ref) => '');

final newsSearchResultsProvider = FutureProvider<List<HotNews>>((ref) async {
  final query = ref.watch(newsSearchQueryProvider);
  if (query.length < 2) return [];
  return ref.read(newsRepositoryProvider).searchNews(query);
});
