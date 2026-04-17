part of 'weekly_bloc.dart';

/// 周报事件
abstract class WeeklyEvent extends Equatable {
  const WeeklyEvent();

  @override
  List<Object?> get props => [];
}

/// 加载最新周报
class LoadWeekly extends WeeklyEvent {
  const LoadWeekly();
}

/// 加载历史周报
class LoadWeeklyHistory extends WeeklyEvent {
  final int limit;

  const LoadWeeklyHistory({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

/// 分享周报
class ShareWeekly extends WeeklyEvent {
  final String weeklyId;

  const ShareWeekly(this.weeklyId);

  @override
  List<Object?> get props => [weeklyId];
}
