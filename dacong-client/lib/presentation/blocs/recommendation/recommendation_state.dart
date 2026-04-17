part of 'recommendation_bloc.dart';

/// 推荐状态基类
abstract class RecommendationState extends Equatable {
  const RecommendationState();

  @override
  List<Object> get props => [];
}

/// 初始状态
class RecommendationInitial extends RecommendationState {}

/// 加载中状态
class RecommendationLoading extends RecommendationState {}

/// 加载成功状态
class RecommendationLoaded extends RecommendationState {
  final List<Recommendation> recommendations;
  final bool hasMore;
  final bool isLoadingMore;

  const RecommendationLoaded(
    this.recommendations, {
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  @override
  List<Object> get props => [recommendations, hasMore, isLoadingMore];

  RecommendationLoaded copyWith({
    List<Recommendation>? recommendations,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return RecommendationLoaded(
      recommendations ?? this.recommendations,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// 错误状态
class RecommendationError extends RecommendationState {
  final String message;

  const RecommendationError(this.message);

  @override
  List<Object> get props => [message];
}
