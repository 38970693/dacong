// GitHub 飙升榜 Repository
// 职责：调用 get-rising-stars Edge Function
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/rising_star_model.dart';

class RisingStarsRepository {
  RisingStarsRepository._();
  static final _instance = RisingStarsRepository._();
  static RisingStarsRepository get instance => _instance;

  final _client = Supabase.instance.client;

  /// 获取飙升榜 Top N
  /// [period] 1d / 7d / 30d
  Future<List<RisingStar>> getRisingStars({
    String period = '7d',
    int limit = 20,
    String? language,
  }) async {
    final queryParams = <String, String>{
      'period': period,
      'limit': limit.toString(),
    };
    if (language != null && language.isNotEmpty) {
      queryParams['language'] = language;
    }

    final response = await _client.functions.invoke(
      'get-rising-stars',
      queryParameters: queryParams,
    );

    if (response.status != 200) {
      throw Exception('获取飙升榜失败: ${response.status}');
    }

    final body = response.data as Map<String, dynamic>;
    final results = body['data'] as List<dynamic>? ?? [];

    return results
        .map((e) => RisingStar.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
