import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dashboard_stats.dart';

class DashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 缓存时间：1分钟
  static const _cacheDuration = Duration(minutes: 1);
  DateTime? _lastFetchTime;
  DashboardStats? _cachedStats;

  Future<DashboardStats> getRealtimeStats() async {
    // 检查缓存
    if (_cachedStats != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _cachedStats!;
    }

    try {
      final response = await _supabase.functions.invoke(
        'get-realtime-stats',
        method: HttpMethod.get,
      );

      final stats = DashboardStats.fromJson(response.data);

      // 更新缓存
      _cachedStats = stats;
      _lastFetchTime = DateTime.now();

      return stats;
    } catch (e) {
      // 如果有缓存，返回缓存数据
      if (_cachedStats != null) {
        return _cachedStats!;
      }
      rethrow;
    }
  }

  Future<TrendData> getTrendData({int days = 7}) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-trend-data',
        method: HttpMethod.get,
        queryParameters: {'days': days.toString()},
      );

      return TrendData.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TopContent>> getTopContent({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('contents')
          .select('id, title, views, likes, helpful_rate')
          .eq('status', 'published')
          .order('views', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => TopContent.fromJson(item))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SearchKeyword>> getTopSearchKeywords({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('search_logs')
          .select('keyword, count(*)')
          .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
          .order('count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => SearchKeyword.fromJson(item))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// 获取待处理事项统计
  Future<PendingTasks> getPendingTasks() async {
    try {
      // 并行查询多个待处理事项
      final results = await Future.wait([
        // 待审核内容数量
        _supabase
            .from('contents')
            .select('id')
            .eq('moderation_status', 'pending'),

        // 待审核评论数量
        _supabase
            .from('comments')
            .select('id')
            .eq('moderation_status', 'pending'),

        // 举报数量
        _supabase
            .from('reports')
            .select('id')
            .eq('status', 'pending'),

        // 用户申诉数量
        _supabase
            .from('user_appeals')
            .select('id')
            .eq('status', 'pending'),
      ]);

      return PendingTasks(
        pendingContents: (results[0] as List).length,
        pendingComments: (results[1] as List).length,
        pendingReports: (results[2] as List).length,
        pendingAppeals: (results[3] as List).length,
      );
    } catch (e) {
      rethrow;
    }
  }

  void clearCache() {
    _cachedStats = null;
    _lastFetchTime = null;
  }
}
