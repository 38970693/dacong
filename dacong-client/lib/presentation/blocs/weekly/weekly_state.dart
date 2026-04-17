part of 'weekly_bloc.dart';

/// 周报状态
abstract class WeeklyState extends Equatable {
  const WeeklyState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class WeeklyInitial extends WeeklyState {}

/// 加载中
class WeeklyLoading extends WeeklyState {}

/// 加载成功（单个周报）
class WeeklyLoaded extends WeeklyState {
  final Weekly weekly;

  const WeeklyLoaded(this.weekly);

  @override
  List<Object?> get props => [weekly];
}

/// 加载成功（历史周报列表）
class WeeklyHistoryLoaded extends WeeklyState {
  final List<Weekly> weeklyList;

  const WeeklyHistoryLoaded(this.weeklyList);

  @override
  List<Object?> get props => [weeklyList];
}

/// 分享中
class WeeklySharing extends WeeklyState {
  final Weekly weekly;

  const WeeklySharing(this.weekly);

  @override
  List<Object?> get props => [weekly];
}

/// 分享成功
class WeeklyShared extends WeeklyState {
  final Weekly weekly;

  const WeeklyShared(this.weekly);

  @override
  List<Object?> get props => [weekly];
}

/// 错误
class WeeklyError extends WeeklyState {
  final String message;

  const WeeklyError(this.message);

  @override
  List<Object?> get props => [message];
}
