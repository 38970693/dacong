// 帖子卡片组件
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/models/post_model.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  const PostCard({super.key, required this.post, this.onTap, this.onLike, this.onComment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
              // 作者行
              Row(
                children: [
                  CircleAvatar(radius: 16, backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text((post.authorName ?? 'U')[0].toUpperCase(),
                      style: TextStyle(color: theme.colorScheme.onPrimaryContainer))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(post.authorName ?? 'Unknown', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text(_timeAgo(post.createdAt), style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ]),
                  ),
                  if (post.topicName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(post.topicName!, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSecondaryContainer)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // 标题
              Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              if (post.content.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(post.content, maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
              ],
              const SizedBox(height: 12),
              // 互动栏
              Row(
                children: [
                  _actionBtn(Icons.favorite_border, '${post.likeCount}', l10n.likes, onLike),
                  const SizedBox(width: 16),
                  _actionBtn(Icons.chat_bubble_outline, '${post.commentCount}', l10n.comments, onComment),
                  const Spacer(),
                  Icon(Icons.share, size: 18, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String count, String label, VoidCallback? onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(count, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ]),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
