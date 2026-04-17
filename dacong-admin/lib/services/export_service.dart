import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class ExportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 通用 CSV 导出方法
  Future<String> exportToCsv(List<Map<String, dynamic>> data, String filename) async {
    try {
      if (data.isEmpty) {
        throw Exception('没有数据可导出');
      }

      // 提取表头
      final headers = data.first.keys.toList();

      // 构建 CSV 行
      final List<List<dynamic>> rows = [headers];

      for (final item in data) {
        rows.add(headers.map((key) => item[key] ?? '').toList());
      }

      final csv = const ListToCsvConverter().convert(rows);
      return await _saveFile(filename, csv);
    } catch (e) {
      throw Exception('导出 CSV 失败: $e');
    }
  }

  /// 通用 Excel 导出方法（使用 CSV 格式，可被 Excel 打开）
  Future<String> exportToExcel(List<Map<String, dynamic>> data, String filename) async {
    try {
      // 确保文件名以 .csv 结尾（Excel 可以打开）
      final excelFilename = filename.endsWith('.csv') ? filename : '$filename.csv';
      return await exportToCsv(data, excelFilename);
    } catch (e) {
      throw Exception('导出 Excel 失败: $e');
    }
  }

  Future<String> exportUsersToCsv() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id, username, email, created_at, last_login_at, status');

      final List<List<dynamic>> rows = [
        ['ID', '用户名', '邮箱', '注册时间', '最后登录', '状态'],
      ];

      for (final user in response as List) {
        rows.add([
          user['id'],
          user['username'],
          user['email'],
          user['created_at'],
          user['last_login_at'] ?? '',
          user['status'],
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);
      return await _saveFile('users_export.csv', csv);
    } catch (e) {
      throw Exception('导出用户数据失败: $e');
    }
  }

  Future<String> exportContentToCsv() async {
    try {
      final response = await _supabase
          .from('contents')
          .select('id, title, author_id, status, views, likes, created_at, published_at');

      final List<List<dynamic>> rows = [
        ['ID', '标题', '作者ID', '状态', '浏览量', '点赞数', '创建时间', '发布时间'],
      ];

      for (final content in response as List) {
        rows.add([
          content['id'],
          content['title'],
          content['author_id'],
          content['status'],
          content['views'],
          content['likes'],
          content['created_at'],
          content['published_at'] ?? '',
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);
      return await _saveFile('content_export.csv', csv);
    } catch (e) {
      throw Exception('导出内容数据失败: $e');
    }
  }

  Future<String> exportCommentsToCsv() async {
    try {
      final response = await _supabase
          .from('comments')
          .select('id, content_id, user_id, content, status, created_at');

      final List<List<dynamic>> rows = [
        ['ID', '内容ID', '用户ID', '评论内容', '状态', '创建时间'],
      ];

      for (final comment in response as List) {
        rows.add([
          comment['id'],
          comment['content_id'],
          comment['user_id'],
          comment['content'],
          comment['status'],
          comment['created_at'],
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);
      return await _saveFile('comments_export.csv', csv);
    } catch (e) {
      throw Exception('导出评论数据失败: $e');
    }
  }

  Future<String> exportAnalyticsReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from('analytics_daily')
          .select('date, dau, pv, uv, new_users')
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .order('date', ascending: true);

      final List<List<dynamic>> rows = [
        ['日期', 'DAU', 'PV', 'UV', '新增用户'],
      ];

      for (final item in response as List) {
        rows.add([
          item['date'],
          item['dau'],
          item['pv'],
          item['uv'],
          item['new_users'],
        ]);
      }

      final csv = const ListToCsvConverter().convert(rows);
      return await _saveFile('analytics_report.csv', csv);
    } catch (e) {
      throw Exception('导出分析报告失败: $e');
    }
  }

  Future<Map<String, dynamic>> generateAnalyticsJson({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final [dailyStats, topContent, userStats] = await Future.wait([
        _supabase
            .from('analytics_daily')
            .select('date, dau, pv, uv, new_users')
            .gte('date', startDate.toIso8601String())
            .lte('date', endDate.toIso8601String())
            .order('date', ascending: true),
        _supabase
            .from('contents')
            .select('id, title, views, likes')
            .eq('status', 'published')
            .order('views', ascending: false)
            .limit(10),
        _supabase
            .from('users')
            .select('id, created_at')
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String()),
      ]);

      return {
        'period': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
        'daily_stats': dailyStats,
        'top_content': topContent,
        'user_stats': {
          'total_new_users': (userStats as List).length,
        },
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('生成分析报告失败: $e');
    }
  }

  Future<String> _saveFile(String filename, String content) async {
    try {
      final directory = kIsWeb
          ? Directory.current
          : await getApplicationDocumentsDirectory();

      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);

      return file.path;
    } catch (e) {
      throw Exception('保存文件失败: $e');
    }
  }

  Future<void> downloadFile(String filename, String content) async {
    if (kIsWeb) {
      // Web 平台使用浏览器下载
      // TODO: 实现 Web 下载逻辑
      debugPrint('Downloading file on web: $filename');
    } else {
      // 移动/桌面平台保存到文档目录
      await _saveFile(filename, content);
    }
  }
}
