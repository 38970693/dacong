import 'package:flutter/material.dart';
import '../../../core/domain/entities/content.dart';

/// 内容基本信息组件
class ContentInfo extends StatelessWidget {
  final Content content;

  const ContentInfo({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 描述
            Text(
              content.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),

            // 价格信息
            _buildInfoRow(
              context,
              icon: Icons.attach_money,
              label: '价格',
              value: content.priceInfo.isFree
                  ? '免费'
                  : content.priceInfo.paidDescription ?? '付费',
            ),
            const SizedBox(height: 12),

            // 访问方式
            _buildInfoRow(
              context,
              icon: Icons.public,
              label: '访问方式',
              value: content.accessInfo.availableInChina
                  ? '国内可用'
                  : (content.accessInfo.needsVpn ? '需要翻墙' : '国外可用'),
              valueColor: content.accessInfo.availableInChina
                  ? Colors.green
                  : Colors.orange,
            ),
            const SizedBox(height: 12),

            // 安装难度
            _buildInfoRow(
              context,
              icon: Icons.build,
              label: '安装难度',
              value: _getDifficultyText(content.accessInfo.difficulty),
              valueColor: _getDifficultyColor(content.accessInfo.difficulty),
            ),
            const SizedBox(height: 16),

            // 链接
            if (content.officialWebsite != null ||
                content.githubUrl != null) ...[
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (content.officialWebsite != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: 打开官网
                        },
                        icon: const Icon(Icons.language),
                        label: const Text('官网'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (content.githubUrl != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: 打开 GitHub
                        },
                        icon: const Icon(Icons.code),
                        label: const Text('GitHub'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  String _getDifficultyText(InstallDifficulty difficulty) {
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
