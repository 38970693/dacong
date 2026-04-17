import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../core/domain/entities/recommendation.dart';
import '../../../core/domain/usecases/get_recommendations.dart';
import '../../../core/error/failures.dart';

part 'recommendation_event.dart';
part 'recommendation_state.dart';

/// 推荐 BLoC（状态管理）
@injectable
class RecommendationBloc extends Bloc<RecommendationEvent, RecommendationState> {
  final GetRecommendations _getRecommendations;

  RecommendationBloc(this._getRecommendations) : super(RecommendationInitial()) {
    on<LoadRecommendations>(_onLoadRecommendations);
    on<RefreshRecommendations>(_onRefreshRecommendations);
    on<LoadMoreRecommendations>(_onLoadMoreRecommendations);
  }

  Future<void> _onLoadRecommendations(
    LoadRecommendations event,
    Emitter<RecommendationState> emit,
  ) async {
    emit(RecommendationLoading());

    final result = await _getRecommendations(event.scenario);

    result.fold(
      (failure) => emit(RecommendationError(_mapFailureToMessage(failure))),
      (recommendations) => emit(RecommendationLoaded(recommendations)),
    );
  }

  Future<void> _onRefreshRecommendations(
    RefreshRecommendations event,
    Emitter<RecommendationState> emit,
  ) async {
    // 刷新时直接加载，不显示 loading 状态
    final result = await _getRecommendations(event.scenario);

    result.fold(
      (failure) => emit(RecommendationError(_mapFailureToMessage(failure))),
      (recommendations) => emit(RecommendationLoaded(recommendations)),
    );
  }

  Future<void> _onLoadMoreRecommendations(
    LoadMoreRecommendations event,
    Emitter<RecommendationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RecommendationLoaded) return;
    if (currentState.isLoadingMore || !currentState.hasMore) return;

    // 设置加载更多状态
    emit(currentState.copyWith(isLoadingMore: true));

    final result = await _getRecommendations(event.scenario);

    result.fold(
      (failure) {
        // 加载更多失败，恢复之前的状态
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (newRecommendations) {
        // 合并新数据
        final allRecommendations = [
          ...currentState.recommendations,
          ...newRecommendations,
        ];
        emit(RecommendationLoaded(
          allRecommendations,
          hasMore: newRecommendations.isNotEmpty,
          isLoadingMore: false,
        ));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    } else {
      return '未知错误';
    }
  }
}
