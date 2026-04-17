// 快讯卡片组件 - 支持 HN / GH / RSS / PH 多来源
import 'package:flutter/material.dart';
import '../../../data/models/hot_news_model.dart';

class NewsCard extends StatelessWidget {
  final HotNews news;
  final VoidCallback? onTap;
  const NewsCard({super.key, required this.news, this.onTap});

  @override
  Widget build(BuildContext context) {
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
                  _sourceBadge(news.source),
                  const SizedBox(width: 8),
                  if (news.score > 0) ...[
                    Icon(Icons.arrow_upward, size: 14, color: Colors.orange.shade700),
                    Text('${news.score}', style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                  ],
                  if (news.author.isNotEmpty)
                    Text(news.author, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  const Spacer(),
                  Text(_timeAgo(news.fetchedAt), style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                news.title,
                maxLines: 3, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (news.summary.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  news.summary,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
              // GitHub 特有信息
              if (news.source == 'GH') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (news.language != null) ...[
                      _langBadge(news.language!),
                      const SizedBox(width: 12),
                    ],
                    if (news.stars != null) ...[
                      Icon(Icons.star_border, size: 14, color: Colors.amber.shade600),
                      const SizedBox(width: 3),
                      Text(_formatCount(news.stars!), style: TextStyle(fontSize: 12, color: Colors.amber.shade700, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                    ],
                    if (news.forks != null) ...[
                      Icon(Icons.call_split, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 3),
                      Text(_formatCount(news.forks!), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ],
                ),
              ],
              // 标签
              if (news.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4, runSpacing: 4,
                  children: news.tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(tag, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceBadge(String source) {
    final (color, label) = switch (source) {
      'HN'  => (Colors.orange, 'HN'),
      'GH'  => (Colors.black87, 'GitHub'),
      'RSS' => (Colors.purple, 'RSS'),
      'PH'  => (Colors.red, 'PH'),
      'DEV' => (Colors.blueGrey, 'DEV'),
      _     => (Colors.grey, source),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: source == 'GH' ? Colors.black87 : color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _langBadge(String lang) {
    final color = _langColor(lang);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(lang, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Color _langColor(String lang) {
    const map = {
      'Python': Color(0xFF3572A5),
      'JavaScript': Color(0xFFF1E05A),
      'TypeScript': Color(0xFF3178C6),
      'Rust': Color(0xFFDEA584),
      'Go': Color(0xFF00ADD8),
      'Java': Color(0xFFB07219),
      'C++': Color(0xFFF34B7D),
      'C': Color(0xFF555555),
      'Ruby': Color(0xFF701516),
      'Swift': Color(0xFFFF7F50),
      'Kotlin': Color(0xFFA97BFF),
      'Dart': Color(0xFF00B4AB),
      'Shell': Color(0xFF89E051),
    };
    return map[lang] ?? Colors.grey;
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
