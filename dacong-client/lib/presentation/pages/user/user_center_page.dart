import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/injection.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_event.dart';
import '../../blocs/user/user_state.dart';

/// 用户中心页面
class UserCenterPage extends StatelessWidget {
  const UserCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UserBloc>()..add(const UserEvent.loadUser()),
      child: const _UserCenterView(),
    );
  }
}

class _UserCenterView extends StatelessWidget {
  const _UserCenterView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        elevation: 0,
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(state.error!, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<UserBloc>().add(const UserEvent.loadUser()),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          if (state.user == null) {
            return _buildGuestView(context, l10n, theme);
          }

          return _buildUserView(context, state, l10n, theme);
        },
      ),
    );
  }

  Widget _buildGuestView(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, size: 80, color: theme.colorScheme.primary.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text(l10n.notLoggedIn, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(l10n.loginToAccessFeatures, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/login'),
            icon: const Icon(Icons.login),
            label: Text(l10n.signIn),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserView(BuildContext context, UserState state, AppLocalizations l10n, ThemeData theme) {
    final user = state.user!;

    return SingleChildScrollView(
      child: Column(
        children: [
          // 用户信息卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
            ),
            child: Column(
              children: [
                // 头像
                GestureDetector(
                  onTap: () => context.push('/user/profile-edit'),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.surface,
                        backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                        child: user.avatarUrl == null
                            ? Text(
                                (user.username ?? user.email)[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 36,
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 用户名
                Text(
                  user.username ?? user.email,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user.bio != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    user.bio!,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 功能列表
          _buildMenuSection(
            context,
            l10n,
            theme,
            title: l10n.myContent,
            items: [
              _MenuItem(
                icon: Icons.favorite,
                title: l10n.myFavorites,
                subtitle: '${state.favorites.length} ${l10n.items}',
                onTap: () => context.push('/user/favorites'),
              ),
              _MenuItem(
                icon: Icons.history,
                title: l10n.myHistory,
                subtitle: '${state.history.length} ${l10n.items}',
                onTap: () => context.push('/user/history'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildMenuSection(
            context,
            l10n,
            theme,
            title: l10n.settings,
            items: [
              _MenuItem(
                icon: Icons.language,
                title: l10n.language,
                subtitle: _getLanguageName(state.preferences?.language ?? 'zh'),
                onTap: () => _showLanguageDialog(context, state.preferences?.language ?? 'zh'),
              ),
              _MenuItem(
                icon: Icons.palette,
                title: l10n.theme,
                subtitle: _getThemeName(state.preferences?.theme ?? 'system', l10n),
                onTap: () => _showThemeDialog(context, state.preferences?.theme ?? 'system', l10n),
              ),
              _MenuItem(
                icon: Icons.notifications,
                title: l10n.notifications,
                trailing: Switch(
                  value: state.preferences?.notificationsEnabled ?? true,
                  onChanged: (value) {
                    context.read<UserBloc>().add(UserEvent.toggleNotifications(value));
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildMenuSection(
            context,
            l10n,
            theme,
            title: l10n.about,
            items: [
              _MenuItem(
                icon: Icons.info,
                title: l10n.aboutApp,
                onTap: () => context.push('/user/about'),
              ),
              _MenuItem(
                icon: Icons.privacy_tip,
                title: l10n.privacyPolicy,
                onTap: () => context.push('/privacy'),
              ),
              _MenuItem(
                icon: Icons.description,
                title: l10n.termsOfService,
                onTap: () => context.push('/terms'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 退出登录按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context, l10n),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(l10n.signOut, style: const TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme, {
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: items.map((item) => _buildMenuItem(context, theme, item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, ThemeData theme, _MenuItem item) {
    return ListTile(
      leading: Icon(item.icon, color: theme.colorScheme.primary),
      title: Text(item.title),
      subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
      trailing: item.trailing ?? const Icon(Icons.chevron_right),
      onTap: item.onTap,
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      default:
        return code;
    }
  }

  String _getThemeName(String theme, AppLocalizations l10n) {
    switch (theme) {
      case 'light':
        return l10n.lightTheme;
      case 'dark':
        return l10n.darkTheme;
      case 'system':
        return l10n.systemTheme;
      default:
        return theme;
    }
  }

  void _showLanguageDialog(BuildContext context, String currentLanguage) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('中文'),
              value: 'zh',
              groupValue: currentLanguage,
              onChanged: (value) {
                if (value != null) {
                  context.read<UserBloc>().add(UserEvent.toggleLanguage(value));
                  Navigator.pop(dialogContext);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: currentLanguage,
              onChanged: (value) {
                if (value != null) {
                  context.read<UserBloc>().add(UserEvent.toggleLanguage(value));
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, String currentTheme, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.theme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(l10n.lightTheme),
              value: 'light',
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  context.read<UserBloc>().add(UserEvent.toggleTheme(value));
                  Navigator.pop(dialogContext);
                }
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.darkTheme),
              value: 'dark',
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  context.read<UserBloc>().add(UserEvent.toggleTheme(value));
                  Navigator.pop(dialogContext);
                }
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.systemTheme),
              value: 'system',
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  context.read<UserBloc>().add(UserEvent.toggleTheme(value));
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.confirmSignOut),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              // TODO: 实现退出登录逻辑
              Navigator.pop(dialogContext);
              context.go('/');
            },
            child: Text(l10n.signOut, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}
