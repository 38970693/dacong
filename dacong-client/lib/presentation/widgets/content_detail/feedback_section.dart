import 'package:flutter/material.dart';
import '../../../core/domain/entities/content.dart';
import '../../../core/domain/entities/feedback.dart';

/// 用户反馈区域组件
class FeedbackSection extends StatelessWidget {
  final Content content;
  final UserFeedback? userFeedback;
  final bool isSubmitting;
  final Function(FeedbackType type, String? comment) onFeedback;

  const FeedbackSection({
    super.key,
    required this.content,
    required this.userFeedback,
    required this.isSubmitting,
    required this.onFeedback,
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
            Text(
              '用户评价',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // 统计信息
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.thumb_up,
                    label: '有用',
                    count: content.helpfulCount,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.thumb_down,
                    label: '无用',
                    count: content.unhelpfulCount,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 用户反馈按钮
            if (userFeedback == null) ...[
              const Divider(),
              const SizedBox(height: 12),
              Text(
                '这个工具对你有帮助吗？',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () => onFeedback(FeedbackType.helpful, null),
                      icon: const Icon(Icons.thumb_up),
                      label: const Text('有用'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () => onFeedback(FeedbackType.unhelpful, null),
                      icon: const Icon(Icons.thumb_down),
                      label: const Text('无用'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Divider(),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: userFeedback!.type == FeedbackType.helpful
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      userFeedback!.type == FeedbackType.helpful
                          ? Icons.thumb_up
                          : Icons.thumb_down,
                      color: userFeedback!.type == FeedbackType.helpful
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '你已标记为${userFeedback!.type == FeedbackType.helpful ? "有用" : "无用"}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],

            // 提交中状态
            if (isSubmitting) ...[
              const SizedBox(height: 12),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}
