// 模型详情页 - 基础信息 + 评测成绩
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/ai_model.dart';
import '../../../data/models/model_evaluation.dart';
import '../../providers/model_evaluations_provider.dart';
import '../../providers/models_provider.dart';

class ModelDetailPage extends ConsumerWidget {
  final String modelId;

  const ModelDetailPage({super.key, required this.modelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelAsync = ref.watch(modelDetailProvider(modelId));

    return Scaffold(
      appBar: AppBar(
        title: Text(modelAsync.valueOrNull?.name ?? '模型详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: '能力对比',
            onPressed: () => context.push('/compare?ids=$modelId'),
          ),
        ],
      ),
      body: modelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (model) {
          if (model == null) {
            return const Center(child: Text('模型不存在'));
          }
          return ListView(
            children: [
              _ModelHeader(model: model),
              const Divider(height: 32),
              _EvaluationsSection(modelId: modelId),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _ModelHeader extends StatelessWidget {
  final AIModel model;

  const _ModelHeader({required this.model});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            model.name,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${model.vendor} · ${model.category}',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          if (model.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(model.description, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// 评测成绩表格：多 benchmark 横向对比
class _EvaluationsSection extends ConsumerWidget {
  final String modelId;

  const _EvaluationsSection({required this.modelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final evaluationsAsync = ref.watch(modelEvaluationsProvider(modelId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '评测成绩',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        evaluationsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('评测数据加载失败: $e',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.red)),
          ),
          data: (evaluations) {
            if (evaluations.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('暂无评测数据'),
              );
            }
            return _EvaluationsTable(evaluations: evaluations);
          },
        ),
      ],
    );
  }
}

class _EvaluationsTable extends StatelessWidget {
  final List<ModelEvaluation> evaluations;

  const _EvaluationsTable({required this.evaluations});

  @override
  Widget build(BuildContext context) {
    // 同分类的 benchmark 相邻展示，便于横向对比
    final sorted = [...evaluations]..sort((a, b) {
        final byCategory = (a.category ?? '').compareTo(b.category ?? '');
        return byCategory != 0
            ? byCategory
            : a.benchmark.compareTo(b.benchmark);
      });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DataTable(
        columnSpacing: 24,
        headingRowHeight: 40,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 48,
        columns: const [
          DataColumn(label: Text('评测项')),
          DataColumn(label: Text('分类')),
          DataColumn(label: Text('分数'), numeric: true),
          DataColumn(label: Text('来源')),
          DataColumn(label: Text('日期')),
        ],
        rows: sorted.map((e) {
          return DataRow(cells: [
            DataCell(Text(e.benchmark)),
            DataCell(Text(e.category ?? '-')),
            DataCell(Text(
              e.scoreLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
            DataCell(Text(e.source)),
            DataCell(Text(
              e.evalDate.toIso8601String().split('T').first,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )),
          ]);
        }).toList(),
      ),
    );
  }
}
