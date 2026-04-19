import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_api_service.dart';
import '../services/export_service.dart';
import '../widgets/batch_selection_widget.dart';

class ContentManagementPage extends ConsumerStatefulWidget {
  const ContentManagementPage({super.key});

  @override
  ConsumerState<ContentManagementPage> createState() => _ContentManagementPageState();
}

class _ContentManagementPageState extends ConsumerState<ContentManagementPage> {
  final _apiService = AdminApiService();
  final _exportService = ExportService();
  final _searchController = TextEditingController();

  String _selectedStatus = 'pending';
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _isLoading = false;
  List<dynamic> _contents = [];
  int _totalCount = 0;
  final Set<String> _selectedIds = {};
  int _currentIndex = 0;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  bool _showAdvancedFilters = false;

  @override
  void initState() {
    super.initState();
    _loadContents();
    _setupKeyboardShortcuts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setupKeyboardShortcuts() {
    // 快捷键在 build 方法中通过 KeyboardListener 实现
  }

  Future<void> _loadContents() async {
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.getContentList(
        status: _selectedStatus,
        page: _currentPage,
        limit: _pageSize,
        search: _searchController.text,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      setState(() {
        _contents = result['items'] as List;
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

  Future<void> _moderateContent(String action, List<String> ids, {String? reason}) async {
    if (ids.isEmpty) return;

    // 单个操作直接执行
    if (ids.length == 1) {
      try {
        await _apiService.moderateContent(
          action: action,
          contentIds: ids,
          reason: reason,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('操作成功')),
          );
        }

        _selectedIds.clear();
        _loadContents();
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
          final content = _contents.firstWhere(
            (c) => c['id'] == id,
            orElse: () => {'title': '未知'},
          );

          updateProgress(i, content['title'] ?? '未知');

          await _apiService.moderateContent(
            action: action,
            contentIds: [id],
            reason: reason,
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
      _loadContents();
    }
  }

  String _getActionText(String action) {
    switch (action) {
      case 'approve':
        return '通过';
      case 'reject':
        return '拒绝';
      case 'delete':
        return '删除';
      default:
        return '处理';
    }
  }

  Future<void> _batchDeleteContent() async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 ${_selectedIds.length} 条内容吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ids = _selectedIds.toList();
    final success = await BatchOperationDialog.show(
      context: context,
      title: '批量删除内容',
      totalCount: ids.length,
      operation: (updateProgress) async {
        for (int i = 0; i < ids.length; i++) {
          final id = ids[i];
          final content = _contents.firstWhere(
            (c) => c['id'] == id,
            orElse: () => {'title': '未知'},
          );

          updateProgress(i, content['title'] ?? '未知');

          await _apiService.deleteContent([id]);

          if (i < ids.length - 1) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }

        updateProgress(ids.length, null);
      },
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功删除 ${ids.length} 项')),
      );
      _selectedIds.clear();
      _loadContents();
    }
  }

  Future<void> _exportSelectedContent() async {
    try {
      final selectedContents = _contents
          .where((content) => _selectedIds.contains(content['id']))
          .toList();

      final data = selectedContents.map((content) => {
        'ID': content['id'],
        '标题': content['title'] ?? '',
        '内容': content['content'] ?? '',
        '作者': content['profiles']?['username'] ?? '',
        '状态': _getStatusText(content['moderation_status']),
        '创建时间': content['created_at'] ?? '',
      }).toList();

      final filePath = await _exportService.exportToCsv(data, 'content_export_${DateTime.now().millisecondsSinceEpoch}.csv');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出成功: $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  void _showEditDialog(dynamic content) {
    final titleController = TextEditingController(text: content['title']);
    final contentController = TextEditingController(text: content['content']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑内容'),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: '内容',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
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
            onPressed: () async {
              try {
                await _apiService.editContent(
                  contentId: content['id'],
                  title: titleController.text,
                  content: contentController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('编辑成功')),
                  );
                  _loadContents();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('编辑失败: $e')),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (_contents.isEmpty) return;

    final currentContent = _contents[_currentIndex];

    switch (event.logicalKey) {
      case LogicalKeyboardKey.digit1:
        _moderateContent('approve', [currentContent['id']]);
        break;
      case LogicalKeyboardKey.digit2:
        _moderateContent('reject', [currentContent['id']]);
        break;
      case LogicalKeyboardKey.keyE:
        _showEditDialog(currentContent);
        break;
      case LogicalKeyboardKey.keyN:
        if (_currentIndex < _contents.length - 1) {
          setState(() => _currentIndex++);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyPress,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('内容管理'),
          actions: [
            if (_selectedIds.isNotEmpty) ...[
              TextButton.icon(
                icon: const Icon(Icons.check_circle),
                label: Text('批量通过 (${_selectedIds.length})'),
                onPressed: () => _moderateContent('approve', _selectedIds.toList()),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.cancel),
                label: Text('批量拒绝 (${_selectedIds.length})'),
                onPressed: () => _moderateContent('reject', _selectedIds.toList()),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.delete),
                label: Text('批量删除 (${_selectedIds.length})'),
                onPressed: _batchDeleteContent,
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.download),
                label: Text('批量导出 (${_selectedIds.length})'),
                onPressed: _exportSelectedContent,
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: '搜索内容...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onSubmitted: (_) => _loadContents(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _selectedStatus,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('全部')),
                          DropdownMenuItem(value: 'pending', child: Text('待审核')),
                          DropdownMenuItem(value: 'passed', child: Text('已通过')),
                          DropdownMenuItem(value: 'flagged', child: Text('已拒绝')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatus = value;
                              _currentPage = 1;
                            });
                            _loadContents();
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(_showAdvancedFilters ? Icons.filter_list_off : Icons.filter_list),
                        onPressed: () {
                          setState(() {
                            _showAdvancedFilters = !_showAdvancedFilters;
                          });
                        },
                        tooltip: '高级筛选',
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadContents,
                        tooltip: '刷新',
                      ),
                    ],
                  ),
                  if (_showAdvancedFilters) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('排序: '),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _sortBy,
                          items: const [
                            DropdownMenuItem(value: 'created_at', child: Text('创建时间')),
                            DropdownMenuItem(value: 'updated_at', child: Text('更新时间')),
                            DropdownMenuItem(value: 'views', child: Text('浏览量')),
                            DropdownMenuItem(value: 'likes', child: Text('点赞数')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sortBy = value;
                                _currentPage = 1;
                              });
                              _loadContents();
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: _sortOrder,
                          items: const [
                            DropdownMenuItem(value: 'desc', child: Text('降序')),
                            DropdownMenuItem(value: 'asc', child: Text('升序')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sortOrder = value;
                                _currentPage = 1;
                              });
                              _loadContents();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // 快捷键提示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const Icon(Icons.keyboard, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '快捷键: 1-通过 | 2-拒绝 | E-编辑 | N-下一条',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (_contents.isNotEmpty) ...[
                    TextButton.icon(
                      icon: Icon(
                        _selectedIds.length == _contents.length
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 18,
                      ),
                      label: Text(
                        _selectedIds.length == _contents.length ? '取消全选' : '全选',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_selectedIds.length == _contents.length) {
                            _selectedIds.clear();
                          } else {
                            _selectedIds.clear();
                            for (var content in _contents) {
                              _selectedIds.add(content['id']);
                            }
                          }
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),

            // 内容列表
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _contents.isEmpty
                      ? const Center(child: Text('暂无内容'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _contents.length,
                          itemBuilder: (context, index) {
                            final content = _contents[index];
                            final isSelected = _selectedIds.contains(content['id']);
                            final isCurrent = index == _currentIndex;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              color: isCurrent ? Colors.blue.shade50 : null,
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
                                                _selectedIds.add(content['id']);
                                              } else {
                                                _selectedIds.remove(content['id']);
                                              }
                                            });
                                          },
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(content['moderation_status']),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _getStatusText(content['moderation_status']),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (content['profiles'] != null)
                                          Text(
                                            '作者: ${content['profiles']['username']}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        const Spacer(),
                                        Text(
                                          _formatDate(content['created_at']),
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // 标题
                                    Text(
                                      content['title'] ?? '无标题',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),

                                    // 预览
                                    Text(
                                      content['content'] ?? '',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 16),

                                    // 操作按钮
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            // TODO: 查看详情
                                          },
                                          child: const Text('查看详情'),
                                        ),
                                        const SizedBox(width: 8),
                                        FilledButton.tonal(
                                          onPressed: () => _moderateContent('approve', [content['id']]),
                                          child: const Text('通过'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () => _moderateContent('reject', [content['id']]),
                                          child: const Text('拒绝'),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () => _showEditDialog(content),
                                          child: const Text('编辑'),
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
                              _loadContents();
                            }
                          : null,
                    ),
                    Text('第 $_currentPage 页 / 共 ${(_totalCount / _pageSize).ceil()} 页'),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < (_totalCount / _pageSize).ceil()
                          ? () {
                              setState(() => _currentPage++);
                              _loadContents();
                            }
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'passed':
        return Colors.green;
      case 'flagged':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'passed':
        return '已通过';
      case 'flagged':
        return '已拒绝';
      case 'pending':
      default:
        return '待审核';
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
