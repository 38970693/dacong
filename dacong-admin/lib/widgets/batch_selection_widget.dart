import 'package:flutter/material.dart';

/// 批量操作按钮配置
class BatchAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final bool requiresConfirmation;
  final String? confirmTitle;
  final String? confirmMessage;

  const BatchAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
    this.requiresConfirmation = false,
    this.confirmTitle,
    this.confirmMessage,
  });
}

/// 批量选择工具栏组件
class BatchSelectionBar extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final VoidCallback onClearSelection;
  final List<BatchAction> actions;

  const BatchSelectionBar({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onClearSelection,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isAllSelected = selectedCount == totalCount && totalCount > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: selectedCount > 0 ? 60 : 0,
      child: selectedCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 选择状态
                  Checkbox(
                    value: isAllSelected,
                    tristate: true,
                    onChanged: (value) {
                      if (isAllSelected) {
                        onDeselectAll();
                      } else {
                        onSelectAll();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '已选择 $selectedCount 项',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('取消选择'),
                    onPressed: onClearSelection,
                  ),
                  const Spacer(),
                  // 批量操作按钮
                  ...actions.map((action) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildActionButton(context, action),
                      )),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildActionButton(BuildContext context, BatchAction action) {
    if (action.requiresConfirmation) {
      return TextButton.icon(
        icon: Icon(action.icon),
        label: Text(action.label),
        style: TextButton.styleFrom(
          foregroundColor: action.color,
        ),
        onPressed: () => _showConfirmDialog(context, action),
      );
    }

    return TextButton.icon(
      icon: Icon(action.icon),
      label: Text(action.label),
      style: TextButton.styleFrom(
        foregroundColor: action.color,
      ),
      onPressed: action.onPressed,
    );
  }

  Future<void> _showConfirmDialog(BuildContext context, BatchAction action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action.confirmTitle ?? '确认操作'),
        content: Text(
          action.confirmMessage ?? '确定要对 $selectedCount 项执行此操作吗?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: action.color ?? Theme.of(context).colorScheme.primary,
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      action.onPressed();
    }
  }
}

/// 批量操作进度对话框
class BatchOperationDialog extends StatefulWidget {
  final String title;
  final int totalCount;
  final Future<void> Function(void Function(int completed, String? currentItem)) operation;

  const BatchOperationDialog({
    super.key,
    required this.title,
    required this.totalCount,
    required this.operation,
  });

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required int totalCount,
    required Future<void> Function(void Function(int completed, String? currentItem)) operation,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BatchOperationDialog(
        title: title,
        totalCount: totalCount,
        operation: operation,
      ),
    );
    return result ?? false;
  }

  @override
  State<BatchOperationDialog> createState() => _BatchOperationDialogState();
}

class _BatchOperationDialogState extends State<BatchOperationDialog> {
  int _completed = 0;
  String? _currentItem;
  bool _isCompleted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _executeOperation();
  }

  Future<void> _executeOperation() async {
    try {
      await widget.operation((completed, currentItem) {
        if (mounted) {
          setState(() {
            _completed = completed;
            _currentItem = currentItem;
          });
        }
      });

      if (mounted) {
        setState(() {
          _isCompleted = true;
        });

        // 自动关闭对话框
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalCount > 0 ? _completed / widget.totalCount : 0.0;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '操作失败: $_error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              LinearProgressIndicator(
                value: _isCompleted ? 1.0 : progress,
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '进度: $_completed / ${widget.totalCount}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              if (_currentItem != null) ...[
                const SizedBox(height: 8),
                Text(
                  '当前: $_currentItem',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (_isCompleted) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    const Text('操作完成!'),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        if (_error != null)
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('关闭'),
          ),
      ],
    );
  }
}
