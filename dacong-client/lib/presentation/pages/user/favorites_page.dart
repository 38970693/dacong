import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../l10n/app_localizations.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myFavorites),
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.favorites.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_border,
              title: l10n.myFavorites,
              message: l10n.emptyFavorites,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.favorites.length,
            itemBuilder: (context, index) {
              final contentId = state.favorites[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.article),
                  title: Text('Content $contentId'),
                  subtitle: const Text('收藏的内容'),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () {
                      context.read<UserBloc>().add(UserEvent.removeFavorite(contentId));
                    },
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
}
