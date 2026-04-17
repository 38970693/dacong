// 个人中心页 - Profile Page
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/user_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profileAsync = ref.watch(currentProfileProvider);
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('未登录', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                child: Text(l10n.signIn),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: profileAsync.when(
        data: (profile) => _buildProfile(context, ref, profile, l10n, theme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, WidgetRef ref, dynamic profile,
      AppLocalizations l10n, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 头像 + 名称
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: profile?.avatarUrl != null
                ? NetworkImage(profile!.avatarUrl!)
                : null,
            child: profile?.avatarUrl == null
                ? Text(
                    (profile?.username ?? 'U')[0].toUpperCase(),
                    style: TextStyle(fontSize: 28, color: theme.colorScheme.onPrimaryContainer),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(profile?.username ?? 'User', style: theme.textTheme.titleLarge),
          if (profile?.bio != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(profile!.bio!, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            ),
          const SizedBox(height: 20),
          // 数据统计
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem('${profile?.postCount ?? 0}', l10n.myPosts),
              _statItem('${profile?.followerCount ?? 0}', l10n.followers),
              _statItem('${profile?.followingCount ?? 0}', l10n.following),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          // 菜单列表
          _menuItem(context, Icons.article_outlined, l10n.myPosts, () {}),
          _menuItem(context, Icons.favorite_border, l10n.myFavorites, () {}),
          _menuItem(context, Icons.history, l10n.myHistory, () {}),
          _menuItem(context, Icons.notifications_outlined, l10n.notificationSettings, () {}),
          _menuItem(context, Icons.settings_outlined, l10n.settings, () {}),
          _menuItem(context, Icons.language, 'Language / 语言', () => context.push('/lang')),
          const Divider(),
          _menuItem(context, Icons.info_outline, l10n.aboutApp, () {}),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l10n.signOut, style: const TextStyle(color: Colors.red)),
            onTap: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
