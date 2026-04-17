import 'package:flutter/material.dart';
import '../../core/domain/entities/content.dart';

/// 内容卡片组件
class ContentCard extends StatelessWidget {
  final Content content;
  final VoidCallback? onTap;

  const ContentCard({
    super.key,
    required this.content,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和厂商
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          content.vendor,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // 评分
                  if (content.helpfulCount + content.unhelpfulCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.thumb_up,
                            size: 16,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(content.helpfulRate * 100).toInt()}%',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // 描述
              Text(
                content.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // 标签
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // 价格标签
                  _InfoChip(
                    icon: content.priceInfo.isFree
                        ? Icons.money_off
                        : Icons.attach_money,
                    label: content.priceInfo.isFree ? '免费' : '付费',
                    color: content.priceInfo.isFree
                        ? Colors.green
                        : Colors.orange,
                  ),
                  // 访问方式标签
                  _InfoChip(
                    icon: content.accessInfo.availableInChina
                        ? Icons.check_circle
                        : Icons.vpn_key,
                    label: content.accessInfo.availableInChina
                        ? '国内可用'
                        : '需翻墙',
                    color: content.accessInfo.availableInChina
                        ? Colors.blue
                        : Colors.red,
                  ),
                  // 难度标签
                  _InfoChip(
                    icon: Icons.speed,
                    label: _getDifficultyLabel(content.accessInfo.difficulty),
                    color: _getDifficultyColor(content.accessInfo.difficulty),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDifficultyLabel(InstallDifficulty difficulty) {
    switch (difficulty) {
      case InstallDifficulty.easy:
        return '简单';
      case InstallDifficulty.medium:
        return '中等';
      case InstallDifficulty.hard:
        return '困难';
    }
  }

  Color _getDifficultyColor(InstallDifficulty difficulty) {
    switch (difficulty) {
      case InstallDifficulty.easy:
        return Colors.green;
      case InstallDifficulty.medium:
        return Colors.orange;
      case InstallDifficulty.hard:
        return Colors.red;
    }
  }
}

/// 信息芯片
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
