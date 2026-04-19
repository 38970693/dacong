import 'package:flutter/material.dart';
import '../widgets/batch_selection_widget.dart';

/// 批量操作使用示例
///
/// 这个示例展示了如何在自定义页面中使用批量操作组件
class BatchOperationExample extends StatefulWidget {
  const BatchOperationExample({super.key});

  @override
  State<BatchOperationExample> createState() => _BatchOperationExampleState();
}

class _BatchOperationExampleState extends State<BatchOperationExample> {
  final Set<String> _selectedIds = {};
  final List<Map<String, dynamic>> _items = List.generate(
    20,
    (index) => {
      'id': 'item_$index',
      'title': '项目 ${index + 1}',
      'description': '这是第 ${index + 1} 个项目的描述',
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('批量操作示例'),
        actions: [
          if (_selectedIds.isNotEmpty) ...[
            TextButton.icon(
              icon: const Icon(Icons.check_circle),
              label: Text('批量通过 (${_selectedIds.length})'),
              onPressed: _batchApprove,
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.delete),
              label: Text('批量删除 (${_selectedIds.length})'),
              onPressed: _batchDelete,
            ),
          ],
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // 使用 BatchSelectionBar 组件
          BatchSelectionBar(
            selectedCount: _selectedIds.length,
            totalCount: _items.length,
            onSelectAll: () {
              setState(() {
                _selectedIds.clear();
                for (var item in _items) {
                  _selectedIds.add(item['id']);
                }
              });
            },
            onDeselectAll: () {
              setState(() {
                _selectedIds.clear();
              });
            },
            onClearSelection: () {
              setState(() {
                _selectedIds.clear();
              });
            },
            actions: [
              BatchAction(
                label: '批量通过',
                icon: Icons.check_circle,
                onPressed: _batchApprove,
              ),
              BatchAction(
                label: '批量删除',
                icon: Icons.delete,
                color: Colors.red,
                requiresConfirmation: true,
                confirmTitle: '确认删除',
                confirmMessage: '确定要删除 ${_selectedIds.length} 项吗？',
                onPressed: _batchDelete,
              ),
            ],
          ),

          // 列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isSelected = _selectedIds.contains(item['id']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedIds.add(item['id']);
                        } else {
                          _selectedIds.remove(item['id']);
                        }
                      });
                    },
                    title: Text(item['title']),
                    subtitle: Text(item['description']),
                    secondary: const Icon(Icons.article),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _batchApprove() async {
    if (_selectedIds.isEmpty) return;

    final ids = _selectedIds.toList();
    final success = await BatchOperationDialog.show(
      context: context,
      title: '批量通过',
      totalCount: ids.length,
      operation: (updateProgress) async {
        for (int i = 0; i < ids.length; i++) {
          final id = ids[i];
          final item = _items.firstWhere((item) => item['id'] == id);

          updateProgress(i, item['title']);

          // 模拟 API 调用
          await Future.delayed(const Duration(milliseconds: 500));

          if (i < ids.length - 1) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }

        updateProgress(ids.length, null);
      },
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功通过 ${ids.length} 项')),
      );
      setState(() {
        _selectedIds.clear();
      });
    }
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 ${_selectedIds.length} 项吗？此操作不可恢复。'),
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
      title: '批量删除',
      totalCount: ids.length,
      operation: (updateProgress) async {
        for (int i = 0; i < ids.length; i++) {
          final id = ids[i];
          final item = _items.firstWhere((item) => item['id'] == id);

          updateProgress(i, item['title']);

          // 模拟 API 调用
          await Future.delayed(const Duration(milliseconds: 500));

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
      setState(() {
        // 从列表中移除已删除的项
        _items.removeWhere((item) => ids.contains(item['id']));
        _selectedIds.clear();
      });
    }
  }
}
