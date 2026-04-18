import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../core/domain/entities/content.dart';
import '../../../core/domain/usecases/search_content.dart';
import '../../../core/error/failures.dart';
import '../../../data/datasources/local_data_source.dart';

part 'search_event.dart';
part 'search_state.dart';

/// 搜索 BLoC（带防抖处理）
@injectable
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchContent _searchContent;
  final LocalDataSource _localDataSource;
  Timer? _debounceTimer;

  // 当前搜索参数
  String _currentQuery = '';
  String? _currentScenario;
  bool? _currentIsFree;
  bool? _currentAvailableInChina;
  SearchSortType _currentSortType = SearchSortType.relevance;
  int _currentOffset = 0;
  static const int _pageSize = 20;

  SearchBloc(
    this._searchContent,
    this._localDataSource,
  ) : super(const SearchInitial()) {
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<SearchFilterChanged>(_onSearchFilterChanged);
    on<SearchSortChanged>(_onSearchSortChanged);
    on<SearchLoadMore>(_onSearchLoadMore);
    on<SearchCleared>(_onSearchCleared);
    on<LoadSearchHistory>(_onLoadSearchHistory);
    on<DeleteSearchHistoryItem>(_onDeleteSearchHistoryItem);
    on<ClearSearchHistory>(_onClearSearchHistory);

    // 初始化时加载搜索历史
    add(const LoadSearchHistory());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  /// 处理搜索查询变化（带防抖）
  Future<void> _onSearchQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    // 取消之前的防抖计时器
    _debounceTimer?.cancel();

    _currentQuery = event.query.trim();

    // 如果查询为空，返回初始状态
    if (_currentQuery.isEmpty) {
      emit(const SearchInitial());
      return;
    }

    // 设置防抖（500ms）
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      add(const SearchFilterChanged()); // 触发实际搜索
    });
  }

  /// 处理筛选变化
  Future<void> _onSearchFilterChanged(
    SearchFilterChanged event,
    Emitter<SearchState> emit,
  ) async {
    // 更新筛选条件
    if (event.scenario != null) _currentScenario = event.scenario;
    if (event.isFree != null) _currentIsFree = event.isFree;
    if (event.availableInChina != null) {
      _currentAvailableInChina = event.availableInChina;
    }

    // 重置分页
    _currentOffset = 0;

    // 执行搜索
    await _performSearch(emit);
  }

  /// 处理排序变化
  Future<void> _onSearchSortChanged(
    SearchSortChanged event,
    Emitter<SearchState> emit,
  ) async {
    _currentSortType = event.sortType;

    // 如果当前有结果，重新排序
    if (state is SearchLoaded) {
      final currentState = state as SearchLoaded;
      final sortedResults = _sortResults(currentState.results, event.sortType);

      emit(currentState.copyWith(
        results: sortedResults,
        sortType: event.sortType,
      ));
    }
  }

  /// 处理加载更多
  Future<void> _onSearchLoadMore(
    SearchLoadMore event,
    Emitter<SearchState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SearchLoaded) return;
    if (currentState.isLoadingMore || !currentState.hasMore) return;

    // 设置加载更多状态
    emit(currentState.copyWith(isLoadingMore: true));

    // 增加偏移量
    _currentOffset += _pageSize;

    // 执行搜索
    final result = await _searchContent(
      _currentQuery,
      limit: _pageSize,
      offset: _currentOffset,
      scenario: _currentScenario,
      isFree: _currentIsFree,
      availableInChina: _currentAvailableInChina,
      sortBy: _sortTypeToString(_currentSortType),
    );

    result.fold(
      (failure) {
        // 加载失败，恢复状态
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (newResults) {
        // 筛选结果
        final filteredResults = _filterResults(newResults);

        // 合并结果
        final allResults = [...currentState.results, ...filteredResults];

        // 排序
        final sortedResults = _sortResults(allResults, _currentSortType);

        emit(SearchLoaded(
          results: sortedResults,
          query: _currentQuery,
          scenario: _currentScenario,
          isFree: _currentIsFree,
          availableInChina: _currentAvailableInChina,
          sortType: _currentSortType,
          hasMore: newResults.length >= _pageSize,
          isLoadingMore: false,
        ));
      },
    );
  }

  /// 处理清空搜索
  Future<void> _onSearchCleared(
    SearchCleared event,
    Emitter<SearchState> emit,
  ) async {
    _debounceTimer?.cancel();
    _currentQuery = '';
    _currentScenario = null;
    _currentIsFree = null;
    _currentAvailableInChina = null;
    _currentSortType = SearchSortType.relevance;
    _currentOffset = 0;

    emit(const SearchInitial());
  }

  /// 执行搜索
  Future<void> _performSearch(Emitter<SearchState> emit) async {
    if (_currentQuery.isEmpty) {
      emit(const SearchInitial());
      return;
    }

    emit(const SearchLoading());

    // 保存搜索历史
    await _localDataSource.saveSearchHistory(_currentQuery);

    final result = await _searchContent(
      _currentQuery,
      limit: _pageSize,
      offset: _currentOffset,
      scenario: _currentScenario,
      isFree: _currentIsFree,
      availableInChina: _currentAvailableInChina,
      sortBy: _sortTypeToString(_currentSortType),
    );

    result.fold(
      (failure) => emit(SearchError(_mapFailureToMessage(failure))),
      (results) {
        // 筛选结果
        final filteredResults = _filterResults(results);

        // 排序结果
        final sortedResults = _sortResults(filteredResults, _currentSortType);

        if (sortedResults.isEmpty) {
          emit(SearchEmpty(_currentQuery));
        } else {
          emit(SearchLoaded(
            results: sortedResults,
            query: _currentQuery,
            scenario: _currentScenario,
            isFree: _currentIsFree,
            availableInChina: _currentAvailableInChina,
            sortType: _currentSortType,
            hasMore: results.length >= _pageSize,
          ));
        }
      },
    );
  }

  /// 加载搜索历史
  Future<void> _onLoadSearchHistory(
    LoadSearchHistory event,
    Emitter<SearchState> emit,
  ) async {
    final history = await _localDataSource.getSearchHistory();
    final popular = _localDataSource.getPopularSearches();

    emit(SearchInitial(
      searchHistory: history,
      popularSearches: popular,
    ));
  }

  /// 删除搜索历史项
  Future<void> _onDeleteSearchHistoryItem(
    DeleteSearchHistoryItem event,
    Emitter<SearchState> emit,
  ) async {
    await _localDataSource.deleteSearchHistoryItem(event.query);

    // 重新加载历史
    add(const LoadSearchHistory());
  }

  /// 清空搜索历史
  Future<void> _onClearSearchHistory(
    ClearSearchHistory event,
    Emitter<SearchState> emit,
  ) async {
    await _localDataSource.clearSearchHistory();

    // 重新加载历史
    add(const LoadSearchHistory());
  }

  /// 筛选结果
  List<Content> _filterResults(List<Content> results) {
    var filtered = results;

    // 按场景筛选（需要在 Content 实体中添加 scenario 字段）
    // if (_currentScenario != null) {
    //   filtered = filtered.where((c) => c.scenario == _currentScenario).toList();
    // }

    // 按价格筛选
    if (_currentIsFree != null) {
      filtered = filtered
          .where((c) => c.priceInfo.isFree == _currentIsFree)
          .toList();
    }

    // 按国内可用性筛选
    if (_currentAvailableInChina != null) {
      filtered = filtered
          .where((c) =>
              c.accessInfo.availableInChina == _currentAvailableInChina)
          .toList();
    }

    return filtered;
  }

  /// 排序结果
  List<Content> _sortResults(List<Content> results, SearchSortType sortType) {
    final sorted = List<Content>.from(results);

    switch (sortType) {
      case SearchSortType.relevance:
        // 相关度排序（默认由 API 返回）
        break;
      case SearchSortType.rating:
        // 按评分排序
        sorted.sort((a, b) => b.helpfulRate.compareTo(a.helpfulRate));
        break;
      case SearchSortType.viewCount:
        // 按浏览量排序（需要在 Content 实体中添加 viewCount 字段）
        sorted.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
        break;
    }

    return sorted;
  }

  /// 将排序类型转换为字符串
  String _sortTypeToString(SearchSortType sortType) {
    switch (sortType) {
      case SearchSortType.relevance:
        return 'relevance';
      case SearchSortType.rating:
        return 'rating';
      case SearchSortType.viewCount:
        return 'viewCount';
    }
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    } else if (failure is ValidationFailure) {
      return failure.message;
    } else {
      return '未知错误';
    }
  }
}
