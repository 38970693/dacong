import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/domain/entities/recommendation.dart';
import '../../core/accessibility/accessibility_utils.dart';

/// 带无障碍支持的推荐卡片组件
class AccessibleRecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  final VoidCallback onTap;

  const AccessibleRecommendationCard({
    super.key,
    required this.recommendation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final semanticLabel = AccessibilityUtils.generateSemanticLabel(
      label: '推荐工具',
      value: '${recommendation.toolName}，评分${recommendation.rating.toStringAsFixed(1)}分',
      hint: '双击查看详情',
    );

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: true,
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行
                Row(
                  children: [
                    _buildTypeChip(context),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          recommendation.toolName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    _buildRatingChip(),
                  ],
                ),
                const SizedBox(height: 12),
                // 描述
                Semantics(
                  label: '描述: ${recommendation.description}',
                  child: Text(
                    recommendation.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                // 优点
                if (recommendation.pros.isNotEmpty) ...[
                  _buildSection(
                    context,
                    l10n.pros,
                    recommendation.pros,
                    Colors.green,
                    Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 8),
                ],
                // 缺点
                if (recommendation.cons.isNotEmpty) ...[
                  _buildSection(
                    context,
                    l10n.cons,
                    recommendation.cons,
                    Colors.orange,
                    Icons.warning_amber_outlined,
                  ),
                  const SizedBox(height: 8),
                ],
                // 底部信息
                Semantics(
                  label: _buildInfoSemanticLabel(context),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        recommendation.price,
                        Icons.attach_money,
                      ),
                      if (recommendation.availableInChina)
                        _buildInfoChip(
                          l10n.availableInChina,
                          Icons.check_circle,
                          color: Colors.green,
                        )
                      else
                        _buildInfoChip(
                          l10n.needVPN,
                          Icons.vpn_key,
                          color: Colors.orange,
                        ),
                      _buildInfoChip(
                        recommendation.targetAudience,
                        Icons.people,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildInfoSemanticLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final parts = <String>[
      '价格: ${recommendation.price}',
      recommendation.availableInChina ? l10n.availableInChina : l10n.needVPN,
      '目标用户: ${recommendation.targetAudience}',
    ];
    return parts.join(', ');
  }

  Widget _buildTypeChip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String label;
    Color color;

    switch (recommendation.type) {
      case RecommendationType.best:
        label = l10n.recommendationBest;
        color = Colors.amber;
        break;
      case RecommendationType.alternative:
        label = l10n.recommendationAlternative;
        color = Colors.blue;
        break;
      case RecommendationType.free:
        label = l10n.recommendationFree;
        color = Colors.green;
        break;
    }

    return Semantics(
      label: '推荐类型: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingChip() {
    return Semantics(
      label: '评分: ${recommendation.rating.toStringAsFixed(1)}分',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 16, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              recommendation.rating.toStringAsFixed(1),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<String> items,
    Color color,
    IconData icon,
  ) {
    return Semantics(
      label: '$title: ${items.join(', ')}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 20, top: 2),
                child: Text(
                  '• $item',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
