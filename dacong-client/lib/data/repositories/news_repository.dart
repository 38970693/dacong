// 快讯 Repository
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hot_news_model.dart';

class NewsRepository {
  NewsRepository._();
  static final _instance = NewsRepository._();
  static NewsRepository get instance => _instance;

  final _client = Supabase.instance.client;

  /// 获取快讯列表（按时间倒序）
  Future<List<HotNews>> getHotNews({
    int page = 0,
    int pageSize = 20,
    String? source,
  }) async {
    var query = _client.from('hot_news_raw').select('*');

    if (source != null && source.isNotEmpty) {
      query = query.eq('source', source);
    }

    final response = await query
        .order('fetched_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return (response as List<dynamic>)
        .map((e) => HotNews.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取热搜词
  Future<List<Map<String, dynamic>>> getTrendingKeywords({int limit = 10}) async {
    final response = await _client
        .from('trending_keywords')
        .select('*')
        .order('heat_score', ascending: false)
        .limit(limit);

    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// 搜索快讯
  Future<List<HotNews>> searchNews(String query, {int limit = 20}) async {
    final response = await _client
        .from('hot_news_raw')
        .select('*')
        .or('title.ilike.%$query%,summary.ilike.%$query%')
        .order('fetched_at', ascending: false)
        .limit(limit);

    return (response as List<dynamic>)
        .map((e) => HotNews.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
