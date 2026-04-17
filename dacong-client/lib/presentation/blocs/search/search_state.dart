part of 'search_bloc.dart';

/// 搜索状态
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class SearchInitial extends SearchState {
  final List<String> searchHistory;
  final List<String> popularSearches;

  const SearchInitial({
    this.searchHistory = const [],
    this.popularSearches = const [],
  });

  @override
  List<Object?> get props => [searchHistory, popularSearches];
}

/// 搜索中
class SearchLoading extends SearchState {
  const SearchLoading();
}

/// 搜索成功
class SearchLoaded extends SearchState {
  final List<Content> results;
  final String query;
  final String? scenario;
  final bool? isFree;
  final bool? availableInChina;
  final SearchSortType sortType;
  final bool hasMore;
  final bool isLoadingMore;

  const SearchLoaded({
    required this.results,
    required this.query,
    this.scenario,
    this.isFree,
    this.availableInChina,
    this.sortType = SearchSortType.relevance,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  SearchLoaded copyWith({
    List<Content>? results,
    String? query,
    String? scenario,
    bool? isFree,
    bool? availableInChina,
    SearchSortType? sortType,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return SearchLoaded(
      results: results ?? this.results,
      query: query ?? this.query,
      scenario: scenario ?? this.scenario,
      isFree: isFree ?? this.isFree,
      availableInChina: availableInChina ?? this.availableInChina,
      sortType: sortType ?? this.sortType,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        results,
        query,
        scenario,
        isFree,
        availableInChina,
        sortType,
        hasMore,
        isLoadingMore,
      ];
}

/// 搜索失败
class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}

/// 空结果
class SearchEmpty extends SearchState {
  final String query;

  const SearchEmpty(this.query);

  @override
  List<Object?> get props => [query];
}
