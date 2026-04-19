import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/audit_log.dart';
import '../services/audit_log_service.dart';
import '../services/export_service.dart';

class AuditLogsPage extends ConsumerStatefulWidget {
  const AuditLogsPage({super.key});

  @override
  ConsumerState<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends ConsumerState<AuditLogsPage> {
  final _auditLogService = AuditLogService();
  final _exportService = ExportService();

  List<AuditLog> _logs = [];
  int _totalCount = 0;
  int _currentPage = 1;
  final int _pageSize = 50;
  bool _isLoading = false;
  bool _isExporting = false;

  // 筛选条件
  String? _selectedAction;
  String? _selectedResource;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    try {
      final filter = AuditLogFilter(
        action: _selectedAction,
        resource: _selectedResource,
        startDate: _startDate,
        endDate: _endDate,
      );

      final result = await _auditLogService.getAuditLogs(
        page: _currentPage,
        limit: _pageSize,
        filter: filter,
      );

      setState(() {
        _logs = result['items'] as List<AuditLog>;
        _totalCount = result['total'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  Future<void> _exportLogs() async {
    setState(() => _isExporting = true);

    try {
      final filter = AuditLogFilter(
        action: _selectedAction,
        resource: _selectedResource,
        startDate: _startDate,
        endDate: _endDate,
      );

      final csv = await _auditLogService.exportLogsToCSV(filter: filter);

      final filename = 'audit_logs_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      await _exportService.downloadFile(filename, csv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出成功: $filename')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _currentPage = 1;
      });
      _loadLogs();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedAction = null;
      _selectedResource = null;
      _startDate = null;
      _endDate = null;
      _currentPage = 1;
    });
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('操作日志'),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            onPressed: _isExporting ? null : _exportLogs,
            tooltip: '导出 CSV',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 筛选栏
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Row(
                  children: [
                    // 操作类型筛选
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedAction,
                        decoration: const InputDecoration(
                          labelText: '操作类型',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('全部')),
                          ..._auditLogService.getActionTypes().map(
                                (action) => DropdownMenuItem(
                                  value: action,
                                  child: Text(_getActionLabel(action)),
                                ),
                              ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedAction = value;
                            _currentPage = 1;
                          });
                          _loadLogs();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 资源类型筛选
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedResource,
                        decoration: const InputDecoration(
                          labelText: '资源类型',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('全部')),
                          ..._auditLogService.getResourceTypes().map(
                                (resource) => DropdownMenuItem(
                                  value: resource,
                                  child: Text(_getResourceLabel(resource)),
                                ),
                              ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedResource = value;
                            _currentPage = 1;
                          });
                          _loadLogs();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 时间范围选择
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          _startDate != null && _endDate != null
                              ? '${DateFormat('yyyy-MM-dd').format(_startDate!)} - ${DateFormat('yyyy-MM-dd').format(_endDate!)}'
                              : '选择时间范围',
                        ),
                        onPressed: _selectDateRange,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 清除筛选
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearFilters,
                      tooltip: '清除筛选',
                    ),

                    // 刷新
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadLogs,
                      tooltip: '刷新',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 日志列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(child: Text('暂无日志'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('时间')),
                              DataColumn(label: Text('操作人')),
                              DataColumn(label: Text('操作类型')),
                              DataColumn(label: Text('资源类型')),
                              DataColumn(label: Text('IP地址')),
                              DataColumn(label: Text('详情')),
                            ],
                            rows: _logs.map((log) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      DateFormat('yyyy-MM-dd HH:mm:ss')
                                          .format(log.createdAt),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        if (log.avatarUrl != null)
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundImage:
                                                NetworkImage(log.avatarUrl!),
                                          )
                                        else
                                          const CircleAvatar(
                                            radius: 12,
                                            child: Icon(Icons.person, size: 12),
                                          ),
                                        const SizedBox(width: 8),
                                        Text(log.username),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Chip(
                                      label: Text(log.actionLabel),
                                      backgroundColor: _getActionColor(log.action),
                                    ),
                                  ),
                                  DataCell(Text(log.resourceLabel)),
                                  DataCell(
                                    Text(
                                      log.ip ?? '-',
                                      style: const TextStyle(fontFamily: 'monospace'),
                                    ),
                                  ),
                                  DataCell(
                                    log.details != null && log.details!.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.info_outline),
                                            onPressed: () =>
                                                _showDetails(log.details!),
                                            tooltip: '查看详情',
                                          )
                                        : const Text('-'),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),

          // 分页
          if (_totalCount > 0)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _loadLogs();
                          }
                        : null,
                  ),
                  Text(
                    '第 $_currentPage 页 / 共 ${(_totalCount / _pageSize).ceil()} 页 (总计 $_totalCount 条)',
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < (_totalCount / _pageSize).ceil()
                        ? () {
                            setState(() => _currentPage++);
                            _loadLogs();
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getActionLabel(String action) {
    final log = AuditLog(
      id: '',
      userId: '',
      username: '',
      action: action,
      resource: '',
      createdAt: DateTime.now(),
    );
    return log.actionLabel;
  }

  String _getResourceLabel(String resource) {
    final log = AuditLog(
      id: '',
      userId: '',
      username: '',
      action: '',
      resource: resource,
      createdAt: DateTime.now(),
    );
    return log.resourceLabel;
  }

  Color _getActionColor(String action) {
    if (action.contains('delete') || action.contains('ban')) {
      return Colors.red.shade100;
    } else if (action.contains('edit') || action.contains('moderate')) {
      return Colors.orange.shade100;
    } else if (action.contains('login') || action.contains('unban')) {
      return Colors.green.shade100;
    }
    return Colors.blue.shade100;
  }

  void _showDetails(Map<String, dynamic> details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('操作详情'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: details.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${entry.key}:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(entry.value.toString()),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
