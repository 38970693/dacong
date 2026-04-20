import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dashboard_stats.dart';

class DashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 缓存时间：1分钟
  static const _cacheDuration = Duration(minutes: 1);
  DateTime? _lastFetchTime;
  DashboardStats? _cachedStats;

  // 开发模式标志
  static const bool _isDevMode = bool.fromEnvironment('DEV_MODE', defaultValue: false);

  Future<DashboardStats> getRealtimeStats() async {
    // 开发模式：返回模拟数据
    if (_isDevMode) {
      return DashboardStats(
        todayDau: 342,
        todayPv: 5420,
        todayUv: 1250,
        newUsers: 28,
        publishedContent: 856,
        totalUsers: 1250,
        totalContent: 856,
        pendingReview: 12,
        totalComments: 3421,
        pendingComments: 8,
        dauChange: 5.2,
        pvChange: 12.8,
        uvChange: 8.5,
        newUsersChange: -2.3,
      );
    }

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
    // 开发模式：返回模拟数据
    if (_isDevMode) {
      final now = DateTime.now();
      return TrendData(
        labels: List.generate(days, (i) {
          final date = now.subtract(Duration(days: days - i - 1));
          return '${date.month}/${date.day}';
        }),
        dauData: List.generate(days, (i) => 300.0 + i * 10),
        pvData: List.generate(days, (i) => 5000.0 + i * 100),
        uvData: List.generate(days, (i) => 1200.0 + i * 20),
      );
    }

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
    // 开发模式：返回模拟数据
    if (_isDevMode) {
      return List.generate(
        limit,
        (i) => TopContent(
          id: 'content_$i',
          title: '热门内容 ${i + 1}',
          views: 1000 - i * 50,
          likes: 200 - i * 10,
          helpfulRate: 0.85 - i * 0.02,
        ),
      );
    }

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
    // 开发模式：返回模拟数据
    if (_isDevMode) {
      return PendingTasks(
        pendingContents: 12,
        pendingComments: 8,
        pendingReports: 5,
        pendingAppeals: 3,
      );
    }

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
            .from('comment_reports')
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
