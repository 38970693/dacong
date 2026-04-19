import 'package:csv/csv.dart';
import '../models/audit_log.dart';
import 'admin_api_service.dart';

class AuditLogService {
  final _apiService = AdminApiService();

  /// 获取操作日志列表
  Future<Map<String, dynamic>> getAuditLogs({
    int page = 1,
    int limit = 50,
    AuditLogFilter? filter,
  }) async {
    final result = await _apiService.getAdminLogs(
      page: page,
      limit: limit,
      adminId: filter?.userId,
      action: filter?.action,
      startDate: filter?.startDate,
      endDate: filter?.endDate,
    );

    final logs = (result['items'] as List)
        .map((item) => AuditLog.fromJson(item))
        .toList();

    return {
      'items': logs,
      'total': result['total'],
    };
  }

  /// 导出日志为 CSV
  Future<String> exportLogsToCSV({
    AuditLogFilter? filter,
    int maxRecords = 10000,
  }) async {
    final allLogs = <AuditLog>[];
    int page = 1;
    const pageSize = 100;

    // 分页获取所有日志
    while (allLogs.length < maxRecords) {
      final result = await getAuditLogs(
        page: page,
        limit: pageSize,
        filter: filter,
      );

      final logs = result['items'] as List<AuditLog>;
      if (logs.isEmpty) break;

      allLogs.addAll(logs);

      if (logs.length < pageSize) break;
      page++;
    }

    // 构建 CSV
    final List<List<dynamic>> rows = [
      ['时间', '操作人', '操作类型', '资源类型', 'IP地址', '详情'],
    ];

    for (final log in allLogs) {
      rows.add([
        _formatDateTime(log.createdAt),
        log.username,
        log.actionLabel,
        log.resourceLabel,
        log.ip ?? '',
        _formatDetails(log.details),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String _formatDetails(Map<String, dynamic>? details) {
    if (details == null || details.isEmpty) return '';
    return details.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('; ');
  }

  /// 获取可用的操作类型列表
  List<String> getActionTypes() {
    return [
      'moderate_content',
      'edit_content',
      'delete_content',
      'ban_user',
      'unban_user',
      'delete_user',
      'moderate_comment',
      'delete_comment',
      'login',
      'logout',
    ];
  }

  /// 获取可用的资源类型列表
  List<String> getResourceTypes() {
    return [
      'content',
      'user',
      'comment',
      'system',
    ];
  }
}
