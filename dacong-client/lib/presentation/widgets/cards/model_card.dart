// 模型卡片组件 - 支持免费/开源标签
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/models/ai_model.dart';

class ModelCard extends StatelessWidget {
  final AIModel model;
  final VoidCallback? onTap;
  const ModelCard({super.key, required this.model, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 排名
                  if (model.rankOverall != null)
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: _rankColor(model.rankOverall!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '#${model.rankOverall}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(width: 12),
                  // 名称 + 厂商
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(model.name,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                          ),
                          if (model.isFree) ...[
                            const SizedBox(width: 6),
                            _freeBadge(),
                          ] else if (model.hasFreeTier) ...[
                            const SizedBox(width: 6),
                            _freeTierBadge(),
                          ],
                          if (model.isOpenSource) ...[
                            const SizedBox(width: 4),
                            _openSourceBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(model.vendor, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ]),
                  ),
                  // 得分
                  if (model.score != null)
                    Column( crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(
                        l10n.scoreLabel(model.score!.toStringAsFixed(1)),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary, fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(model.category, style: theme.textTheme.bodySmall),
                    ]),
                ],
              ),
              if (model.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  model.description,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
              // 价格信息
              if (model.pricePer1MInput != null || model.contextWindow != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (model.pricePer1MInput != null)
                      _infoChip(Icons.input, model.pricePer1MInput!, Colors.blue),
                    if (model.pricePer1MInput != null && model.pricePer1MOutput != null)
                      const SizedBox(width: 6),
                    if (model.pricePer1MOutput != null)
                      _infoChip(Icons.output, model.pricePer1MOutput!, Colors.green),
                    if (model.contextWindow != null) ...[
                      const SizedBox(width: 6),
                      _infoChip(Icons.memory, model.contextWindow!, Colors.purple),
                    ],
                  ],
                ),
              ],
              if (model.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4, runSpacing: 4,
                  children: model.tags.take(4).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(tag, style: TextStyle(fontSize: 11, color: theme.colorScheme.onPrimaryContainer)),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _freeBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
    child: const Text('🆓免费', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _freeTierBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(4)),
    child: const Text('⬇️免费额', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _openSourceBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(color: Colors.blue.shade700, borderRadius: BorderRadius.circular(4)),
    child: const Text('📂开源', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _infoChip(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(fontSize: 11, color: color)),
    ]),
  );

  Color _rankColor(int rank) {
    if (rank <= 3) return Colors.amber.shade700;
    if (rank <= 10) return Colors.deepPurple;
    if (rank <= 20) return Colors.blue;
    return Colors.grey;
  }
}
