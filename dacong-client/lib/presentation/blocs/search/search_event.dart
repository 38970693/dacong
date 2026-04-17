part of 'search_bloc.dart';

/// 排序类型
enum SearchSortType {
  relevance,  // 相关度
  rating,     // 评分
  viewCount,  // 浏览量
}

/// 搜索事件
abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

/// 搜索查询变化（带防抖）
class SearchQueryChanged extends SearchEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// 筛选变化
class SearchFilterChanged extends SearchEvent {
  final String? scenario;
  final bool? isFree;
  final bool? availableInChina;

  const SearchFilterChanged({
    this.scenario,
    this.isFree,
    this.availableInChina,
  });

  @override
  List<Object?> get props => [scenario, isFree, availableInChina];
}

/// 排序变化
class SearchSortChanged extends SearchEvent {
  final SearchSortType sortType;

  const SearchSortChanged(this.sortType);

  @override
  List<Object?> get props => [sortType];
}

/// 加载更多
class SearchLoadMore extends SearchEvent {
  const SearchLoadMore();
}

/// 清空搜索
class SearchCleared extends SearchEvent {
  const SearchCleared();
}

/// 加载搜索历史
class LoadSearchHistory extends SearchEvent {
  const LoadSearchHistory();
}

/// 删除搜索历史项
class DeleteSearchHistoryItem extends SearchEvent {
  final String query;

  const DeleteSearchHistoryItem(this.query);

  @override
  List<Object?> get props => [query];
}

/// 清空搜索历史
class ClearSearchHistory extends SearchEvent {
  const ClearSearchHistory();
}
