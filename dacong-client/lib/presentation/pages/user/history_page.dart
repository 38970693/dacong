import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/di/injection.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_event.dart';
import '../../blocs/user/user_state.dart';
import '../../widgets/empty_state.dart';

/// 浏览历史页面
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UserBloc>()..add(const UserEvent.loadHistory()),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myHistory),
        actions: [
          BlocBuilder<UserBloc, UserState>(
            builder: (context, state) {
              if (state.history.isEmpty) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _showClearDialog(context, l10n),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.history.isEmpty) {
            return EmptyState(
              icon: Icons.history,
              title: l10n.myHistory,
              message: l10n.emptyHistory,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.history.length,
            itemBuilder: (context, index) {
              final item = state.history[index];
              final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: _getIconForType(item.contentType),
                  title: Text(item.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.summary != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.summary!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(item.viewedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: 跳转到内容详情页
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _getIconForType(String type) {
    IconData icon;
    switch (type) {
      case 'recommendation':
        icon = Icons.recommend;
        break;
      case 'guide':
        icon = Icons.menu_book;
        break;
      case 'weekly':
        icon = Icons.calendar_today;
        break;
      default:
        icon = Icons.article;
    }
    return Icon(icon);
  }

  void _showClearDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearHistory),
        content: Text(l10n.confirmClearHistory),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<UserBloc>().add(const UserEvent.clearHistory());
              Navigator.pop(dialogContext);
            },
            child: Text(l10n.confirm, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
