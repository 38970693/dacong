import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../core/domain/entities/weekly.dart';
import '../../../core/domain/usecases/get_weekly_report.dart';
import '../../../core/error/failures.dart';

part 'weekly_event.dart';
part 'weekly_state.dart';

/// 周报 BLoC（状态管理）
@injectable
class WeeklyBloc extends Bloc<WeeklyEvent, WeeklyState> {
  final GetWeeklyReport _getWeeklyReport;

  WeeklyBloc(this._getWeeklyReport) : super(WeeklyInitial()) {
    on<LoadWeekly>(_onLoadWeekly);
    on<LoadWeeklyHistory>(_onLoadWeeklyHistory);
    on<ShareWeekly>(_onShareWeekly);
  }

  Future<void> _onLoadWeekly(
    LoadWeekly event,
    Emitter<WeeklyState> emit,
  ) async {
    emit(WeeklyLoading());

    final result = await _getWeeklyReport();

    result.fold(
      (failure) => emit(WeeklyError(_mapFailureToMessage(failure))),
      (weekly) => emit(WeeklyLoaded(weekly)),
    );
  }

  Future<void> _onLoadWeeklyHistory(
    LoadWeeklyHistory event,
    Emitter<WeeklyState> emit,
  ) async {
    emit(WeeklyLoading());

    final result = await _getWeeklyReport.getHistory(limit: event.limit);

    result.fold(
      (failure) => emit(WeeklyError(_mapFailureToMessage(failure))),
      (weeklyList) => emit(WeeklyHistoryLoaded(weeklyList)),
    );
  }

  Future<void> _onShareWeekly(
    ShareWeekly event,
    Emitter<WeeklyState> emit,
  ) async {
    // 分享功能：生成图卡并分享
    // 这里只是记录分享事件，实际分享由 UI 层处理
    final currentState = state;
    if (currentState is WeeklyLoaded) {
      emit(WeeklySharing(currentState.weekly));

      // 模拟分享完成
      await Future.delayed(const Duration(milliseconds: 500));

      emit(WeeklyShared(currentState.weekly));

      // 恢复到加载状态
      emit(WeeklyLoaded(currentState.weekly));
    }
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
