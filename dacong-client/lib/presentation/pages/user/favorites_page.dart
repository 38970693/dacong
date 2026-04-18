import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/entities/favorite_content.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_event.dart';
import '../../blocs/user/user_state.dart';
import '../../widgets/empty_state.dart';

/// 收藏列表页面
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UserBloc>()..add(const UserEvent.loadFavorites()),
      child: const _FavoritesView(),
    );
  }
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myFavorites),
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.favoriteContents.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_border,
              title: l10n.myFavorites,
              message: l10n.emptyFavorites,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<UserBloc>().add(const UserEvent.loadFavorites());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.favoriteContents.length,
              itemBuilder: (context, index) {
                final favorite = state.favoriteContents[index];
                return _FavoriteCard(favorite: favorite);
              },
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final FavoriteContent favorite;

  const _FavoriteCard({required this.favorite});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: 跳转到内容详情页
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和收藏按钮
              Row(
                children: [
                  Expanded(
                    child: Text(
                      favorite.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () {
                      context.read<UserBloc>().add(
                            UserEvent.removeFavorite(favorite.contentId),
                          );
                    },
                    tooltip: '取消收藏',
                  ),
                ],
              ),

              // 摘要
              if (favorite.summary != null) ...[
                const SizedBox(height: 8),
                Text(
                  favorite.summary!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // 元数据
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  // 内容类型
                  _buildMetaChip(
                    context,
                    _getContentTypeLabel(favorite.contentType),
                    Icons.category,
                    theme.colorScheme.primary,
                  ),

                  // 场景
                  if (favorite.scenario != null)
                    _buildMetaChip(
                      context,
                      favorite.scenario!,
                      Icons.label,
                      Colors.orange,
                    ),

                  // 浏览量
                  _buildMetaInfo(
                    context,
                    Icons.visibility,
                    '${favorite.viewCount}',
                  ),

                  // 点赞数
                  _buildMetaInfo(
                    context,
                    Icons.thumb_up,
                    '${favorite.helpfulCount}',
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 收藏时间
              Text(
                '收藏于 ${_formatDate(favorite.favoritedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildMetaInfo(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getContentTypeLabel(String type) {
    switch (type) {
      case 'recommendation':
        return '推荐';
      case 'guide':
        return '指南';
      case 'weekly':
        return '周报';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}分钟前';
      }
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}
