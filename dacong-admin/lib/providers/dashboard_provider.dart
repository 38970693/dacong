import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_stats.dart';
import '../services/dashboard_service.dart';

final dashboardServiceProvider = Provider((ref) => DashboardService());

final realtimeStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getRealtimeStats();
});

final trendDataProvider = FutureProvider.family<TrendData, int>((ref, days) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getTrendData(days: days);
});

final topContentProvider = FutureProvider.family<List<TopContent>, int>((ref, limit) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getTopContent(limit: limit);
});

final topSearchKeywordsProvider = FutureProvider.family<List<SearchKeyword>, int>((ref, limit) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getTopSearchKeywords(limit: limit);
});

final pendingTasksProvider = FutureProvider<PendingTasks>((ref) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getPendingTasks();
});
