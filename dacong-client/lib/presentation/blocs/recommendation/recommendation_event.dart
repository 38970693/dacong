part of 'recommendation_bloc.dart';

/// 推荐事件基类
abstract class RecommendationEvent extends Equatable {
  const RecommendationEvent();

  @override
  List<Object> get props => [];
}

/// 加载推荐事件
class LoadRecommendations extends RecommendationEvent {
  final String scenario;

  const LoadRecommendations(this.scenario);

  @override
  List<Object> get props => [scenario];
}

/// 刷新推荐事件
class RefreshRecommendations extends RecommendationEvent {
  final String scenario;

  const RefreshRecommendations(this.scenario);

  @override
  List<Object> get props => [scenario];
}

/// 加载更多推荐事件
class LoadMoreRecommendations extends RecommendationEvent {
  final String scenario;

  const LoadMoreRecommendations(this.scenario);

  @override
  List<Object> get props => [scenario];
}
