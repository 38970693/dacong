import 'package:flutter/material.dart';

/// 优缺点列表组件
class ProsConsList extends StatelessWidget {
  final List<String> pros;
  final List<String> cons;

  const ProsConsList({
    super.key,
    required this.pros,
    required this.cons,
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
            // 优点
            if (pros.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '优点',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...pros.map((pro) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pro,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            // 缺点
            if (cons.isNotEmpty) ...[
              if (pros.isNotEmpty) const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '缺点',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...cons.map((con) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.remove_circle_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            con,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            // 如果没有优缺点数据
            if (pros.isEmpty && cons.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '暂无优缺点信息',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
