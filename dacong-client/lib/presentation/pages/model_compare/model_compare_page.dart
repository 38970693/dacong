// 模型能力对比页 - 多选模型横向对比能力字段
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/ai_model.dart';
import '../../../data/models/model_capability.dart';
import '../../providers/model_comparison_provider.dart';
import '../../providers/models_provider.dart';
import '../../widgets/common/loading_error_widget.dart';

class ModelComparePage extends ConsumerStatefulWidget {
  /// 从模型详情页等入口带入的预选模型
  final List<String> initialIds;

  const ModelComparePage({super.key, this.initialIds = const []});

  @override
  ConsumerState<ModelComparePage> createState() => _ModelComparePageState();
}

class _ModelComparePageState extends ConsumerState<ModelComparePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(compareSelectionProvider.notifier).seed(widget.initialIds);
      // 选择器候选列表复用综合榜数据
      if (ref.read(rankingProvider).models.isEmpty) {
        ref.read(rankingProvider.notifier).loadInitial();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(compareSelectionProvider);
    final comparisonAsync = ref.watch(modelComparisonProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('模型能力对比'),
        actions: [
          if (selected.isNotEmpty)
            TextButton(
              onPressed: () =>
                  ref.read(compareSelectionProvider.notifier).clear(),
              child: const Text('清空'),
            ),
        ],
      ),
      body: Column(
        children: [
          _SelectionBar(onAdd: () => _openPicker(context)),
          const Divider(height: 1),
          Expanded(
            child: selected.isEmpty
                ? const EmptyWidget(
                    icon: Icons.compare_arrows,
                    message: '请选择模型开始对比（最多 $kMaxCompareModels 个）',
                  )
                : comparisonAsync.when(
                    loading: () => const LoadingWidget(),
                    error: (e, _) => AppErrorWidget(
                      message: '对比数据加载失败: $e',
                      onRetry: () => ref.invalidate(modelComparisonProvider),
                    ),
                    data: (models) => models.isEmpty
                        ? const EmptyWidget(message: '暂无能力数据')
                        : _ComparisonTable(models: models),
                  ),
          ),
        ],
      ),
    );
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ModelPickerSheet(),
    );
  }
}

/// 已选模型 chips + 添加入口
class _SelectionBar extends ConsumerWidget {
  final VoidCallback onAdd;

  const _SelectionBar({required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.watch(compareSelectionProvider);
    final notifier = ref.read(compareSelectionProvider.notifier);
    final candidates = ref.watch(rankingProvider).models;

    String nameOf(String id) {
      final match = candidates.where((m) => m.id == id);
      return match.isEmpty ? id : match.first.name;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...selectedIds.map((id) => InputChip(
                label: Text(nameOf(id)),
                onDeleted: () => notifier.toggle(id),
              )),
          if (selectedIds.length < kMaxCompareModels)
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('添加模型'),
              onPressed: onAdd,
            ),
        ],
      ),
    );
  }
}

/// 底部选择器：从综合榜挑选待对比模型
class _ModelPickerSheet extends ConsumerWidget {
  const _ModelPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rankingProvider);
    final selectedIds = ref.watch(compareSelectionProvider);
    final notifier = ref.read(compareSelectionProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      expand: false,
      builder: (_, scrollController) {
        if (state.isLoading && state.models.isEmpty) {
          return const LoadingWidget();
        }
        if (state.error != null && state.models.isEmpty) {
          return AppErrorWidget(
            message: '模型列表加载失败: ${state.error}',
            onRetry: () => ref.read(rankingProvider.notifier).loadInitial(),
          );
        }

        return ListView.builder(
          controller: scrollController,
          itemCount: state.models.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  '选择模型',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              );
            }

            final AIModel model = state.models[index - 1];
            final isSelected = selectedIds.contains(model.id);

            return CheckboxListTile(
              value: isSelected,
              title: Text(model.name),
              subtitle: Text('${model.vendor} · ${model.category}'),
              onChanged: (_) {
                final ok = notifier.toggle(model.id);
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('最多对比 $kMaxCompareModels 个模型'),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

/// 横评表：行为能力项，列为模型
class _ComparisonTable extends StatelessWidget {
  final List<ModelCapability> models;

  const _ComparisonTable({required this.models});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 所有模型评测项的并集，作为表格末尾的评测行
    final benchmarks = <String>{
      for (final m in models)
        for (final e in m.evaluations) e.benchmark,
    }.toList()
      ..sort();

    final rows = <_CapabilityRow>[
      _CapabilityRow('厂商', (m) => m.vendor),
      _CapabilityRow('分类', (m) => m.category),
      _CapabilityRow('开源', (m) => m.isOpenSource ? '是' : '否'),
      _CapabilityRow('上下文窗口', (m) => m.contextWindowLabel),
      _CapabilityRow('最大输出', (m) => m.maxOutputLabel),
      _CapabilityRow('首 token 延迟', (m) => m.latencyLabel),
      _CapabilityRow('输出速度', (m) => m.throughputLabel),
      _CapabilityRow('多模态输入', (m) => m.multimodalLabel),
      _CapabilityRow('工具调用', (m) => m.toolUse ? '支持' : '不支持'),
      _CapabilityRow('可微调', (m) => m.fineTunable ? '支持' : '不支持'),
      _CapabilityRow('价格 (入/出 每1M)', (m) => m.priceLabel),
      for (final benchmark in benchmarks)
        _CapabilityRow(
          benchmark,
          (m) => m.evaluationsByBenchmark[benchmark]?.scoreLabel ?? '-',
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DataTable(
          columnSpacing: 24,
          headingRowHeight: 48,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 56,
          columns: [
            const DataColumn(label: Text('能力项')),
            ...models.map((m) => DataColumn(
                  label: Text(
                    m.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )),
          ],
          rows: rows.map((row) {
            return DataRow(cells: [
              DataCell(Text(
                row.label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey.shade700),
              )),
              ...models.map((m) => DataCell(Text(row.value(m)))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _CapabilityRow {
  final String label;
  final String Function(ModelCapability) value;

  const _CapabilityRow(this.label, this.value);
}
