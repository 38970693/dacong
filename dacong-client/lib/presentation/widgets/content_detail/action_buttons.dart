import 'package:flutter/material.dart';
import '../../../core/domain/entities/content.dart';

/// 底部操作按钮组件
class ActionButtons extends StatelessWidget {
  final Content content;

  const ActionButtons({
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 查看安装教程
            if (content.accessInfo.installGuideUrl != null)
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: 打开安装教程
                },
                icon: const Icon(Icons.book),
                label: const Text('查看安装教程'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

            const SizedBox(height: 12),

            // 访问官网
            if (content.officialWebsite != null)
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: 打开官网
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('访问官网'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
