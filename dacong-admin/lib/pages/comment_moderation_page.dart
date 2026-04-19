import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_api_service.dart';
import '../widgets/batch_selection_widget.dart';

class CommentModerationPage extends ConsumerStatefulWidget {
  const CommentModerationPage({super.key});

  @override
  ConsumerState<CommentModerationPage> createState() => _CommentModerationPageState();
}

class _CommentModerationPageState extends ConsumerState<CommentModerationPage> {
  final _apiService = AdminApiService();

  String _selectedStatus = 'pending';
  bool _reportedOnly = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _isLoading = false;
  List<dynamic> _comments = [];
  int _totalCount = 0;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.getCommentList(
        page: _currentPage,
        limit: _pageSize,
        status: _selectedStatus,
        reportedOnly: _reportedOnly,
      );

      setState(() {
        _comments = result['items'] as List;
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

  Future<void> _moderateComment(
    String action,
    List<String> ids, {
    String? reason,
    bool banUser = false,
  }) async {
    if (ids.isEmpty) return;

    // 单个操作直接执行
    if (ids.length == 1) {
      try {
        await _apiService.moderateComment(
          action: action,
          commentIds: ids,
          reason: reason,
          banUser: banUser,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('操作成功')),
          );
        }

        _selectedIds.clear();
        _loadComments();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('操作失败: $e')),
          );
        }
      }
      return;
    }

    // 批量操作显示进度对话框
    final success = await BatchOperationDialog.show(
      context: context,
      title: '批量${_getActionText(action)}',
      totalCount: ids.length,
      operation: (updateProgress) async {
        for (int i = 0; i < ids.length; i++) {
          final id = ids[i];
          final comment = _comments.firstWhere(
            (c) => c['id'] == id,
            orElse: () => {'content': '未知'},
          );

          final content = comment['content'] ?? '未知';
          final preview = content.length > 20 ? '${content.substring(0, 20)}...' : content;
          updateProgress(i, preview);

          await _apiService.moderateComment(
            action: action,
            commentIds: [id],
            reason: reason,
            banUser: banUser,
          );

          // 避免请求过快
          if (i < ids.length - 1) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }

        updateProgress(ids.length, null);
      },
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功${_getActionText(action)} ${ids.length} 项')),
      );
      _selectedIds.clear();
      _loadComments();
    }
  }

  String _getActionText(String action) {
    switch (action) {
      case 'approve':
        return '通过';
      case 'delete':
        return '删除';
      default:
        return '处理';
    }
  }

  void _showModerationDialog(dynamic comment) {
    showDialog(
      context: context,
      builder: (context) {
        bool banUser = false;
        final reasonController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('审核评论'),
            content: SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 评论内容
                  Text('评论内容:', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      comment['highlighted_content'] ?? comment['content'] ?? '',
                      style: TextStyle(
                        color: comment['has_sensitive_words'] == true
                            ? Colors.red
                            : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 举报信息
                  if (comment['reports'] != null && comment['reports'].isNotEmpty) ...[
                    Text('举报信息:', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...List.generate(
                      comment['reports'].length,
                      (index) {
                        final report = comment['reports'][index];
                        return Card(
                          child: ListTile(
                            dense: true,
                            title: Text('原因: ${_getReasonText(report['reason'])}'),
                            subtitle: report['description'] != null
                                ? Text(report['description'])
                                : null,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 处理原因
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: '处理原因（可选）',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // 是否封禁用户
                  CheckboxListTile(
                    value: banUser,
                    onChanged: (value) {
                      setState(() => banUser = value ?? false);
                    },
                    title: const Text('同时封禁该用户'),
                    dense: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.pop(context);
                  _moderateComment(
                    'approve',
                    [comment['id']],
                    reason: reasonController.text,
                  );
                },
                child: const Text('通过'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _moderateComment(
                    'delete',
                    [comment['id']],
                    reason: reasonController.text,
                    banUser: banUser,
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBatchDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        bool banUser = false;
        final reasonController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('批量删除评论 (${_selectedIds.length} 项)'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('确定要删除 ${_selectedIds.length} 条评论吗？'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: '处理原因（可选）',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: banUser,
                    onChanged: (value) {
                      setState(() => banUser = value ?? false);
                    },
                    title: const Text('同时封禁这些用户'),
                    dense: true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _moderateComment(
                    'delete',
                    _selectedIds.toList(),
                    reason: reasonController.text,
                    banUser: banUser,
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('评论审核'),
        actions: [
          if (_selectedIds.isNotEmpty) ...[
            TextButton.icon(
              icon: const Icon(Icons.check_circle),
              label: Text('批量通过 (${_selectedIds.length})'),
              onPressed: () => _moderateComment('approve', _selectedIds.toList()),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.delete),
              label: Text('批量删除 (${_selectedIds.length})'),
              onPressed: _showBatchDeleteDialog,
            ),
          ],
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // 筛选栏
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('全部')),
                    DropdownMenuItem(value: 'pending', child: Text('待审核')),
                    DropdownMenuItem(value: 'flagged', child: Text('已标记')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatus = value;
                        _currentPage = 1;
                      });
                      _loadComments();
                    }
                  },
                ),
                const SizedBox(width: 16),
                FilterChip(
                  label: const Text('只显示被举报的'),
                  selected: _reportedOnly,
                  onSelected: (selected) {
                    setState(() {
                      _reportedOnly = selected;
                      _currentPage = 1;
                    });
                    _loadComments();
                  },
                ),
                const Spacer(),
                if (_comments.isNotEmpty) ...[
                  TextButton.icon(
                    icon: Icon(
                      _selectedIds.length == _comments.length
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 18,
                    ),
                    label: Text(
                      _selectedIds.length == _comments.length ? '取消全选' : '全选',
                    ),
                    onPressed: () {
                      setState(() {
                        if (_selectedIds.length == _comments.length) {
                          _selectedIds.clear();
                        } else {
                          _selectedIds.clear();
                          for (var comment in _comments) {
                            _selectedIds.add(comment['id']);
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadComments,
                  tooltip: '刷新',
                ),
              ],
            ),
          ),

          // 评论列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(child: Text('暂无评论'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final isSelected = _selectedIds.contains(comment['id']);
                          final hasSensitive = comment['has_sensitive_words'] == true;
                          final reportCount = comment['report_count'] ?? 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: hasSensitive ? Colors.red.shade50 : null,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 头部信息
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (checked) {
                                          setState(() {
                                            if (checked == true) {
                                              _selectedIds.add(comment['id']);
                                            } else {
                                              _selectedIds.remove(comment['id']);
                                            }
                                          });
                                        },
                                      ),
                                      if (hasSensitive)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            '含敏感词',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      if (reportCount > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '$reportCount 次举报',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 8),
                                      if (comment['profiles'] != null)
                                        Text(
                                          '用户: ${comment['profiles']['username']}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      const Spacer(),
                                      Text(
                                        _formatDate(comment['created_at']),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // 评论内容
                                  Text(
                                    comment['highlighted_content'] ?? comment['content'] ?? '',
                                    style: TextStyle(
                                      color: hasSensitive ? Colors.red.shade900 : null,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // 所属帖子
                                  if (comment['posts'] != null)
                                    Text(
                                      '帖子: ${comment['posts']['title']}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey,
                                          ),
                                    ),
                                  const SizedBox(height: 16),

                                  // 操作按钮
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => _showModerationDialog(comment),
                                        child: const Text('详细审核'),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton.tonal(
                                        onPressed: () => _moderateComment('approve', [comment['id']]),
                                        child: const Text('通过'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () => _moderateComment('delete', [comment['id']]),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('删除'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
                            _loadComments();
                          }
                        : null,
                  ),
                  Text('第 $_currentPage 页 / 共 ${(_totalCount / _pageSize).ceil()} 页'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < (_totalCount / _pageSize).ceil()
                        ? () {
                            setState(() => _currentPage++);
                            _loadComments();
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

  String _getReasonText(String reason) {
    switch (reason) {
      case 'spam':
        return '垃圾信息';
      case 'offensive':
        return '冒犯性内容';
      case 'inappropriate':
        return '不当内容';
      case 'other':
      default:
        return '其他';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}
