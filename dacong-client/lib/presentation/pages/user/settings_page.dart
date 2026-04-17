import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_event.dart';
import '../../blocs/user/user_state.dart';

/// 设置页面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UserBloc>()..add(const UserEvent.loadUser()),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final preferences = state.preferences;
          if (preferences == null) {
            return Center(child: Text(l10n.error));
          }

          return ListView(
            children: [
              _buildSection(
                context,
                l10n,
                theme,
                title: l10n.language,
                children: [
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(l10n.language),
                    subtitle: Text(_getLanguageName(preferences.language)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguageDialog(context, preferences.language),
                  ),
                ],
              ),
              _buildSection(
                context,
                l10n,
                theme,
                title: l10n.theme,
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: Text(l10n.theme),
                    subtitle: Text(_getThemeName(preferences.theme, l10n)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemeDialog(context, preferences.theme, l10n),
                  ),
                ],
              ),
              _buildSection(
                context,
                l10n,
                theme,
                title: l10n.notifications,
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications),
                    title: Text(l10n.notifications),
                    subtitle: const Text('接收推送通知'),
                    value: preferences.notificationsEnabled,
                    onChanged: (value) {
                      context.read<UserBloc>().add(UserEvent.toggleNotifications(value));
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.article),
                    title: const Text('周报推送'),
                    subtitle: const Text('每周接收精选内容'),
                    value: preferences.weeklyReportEnabled,
                    onChanged: (value) {
                      context.read<UserBloc>().add(UserEvent.toggleWeeklyReport(value));
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.update),
                    title: const Text('工具更新通知'),
                    subtitle: const Text('关注的工具有更新时通知'),
                    value: preferences.toolUpdateEnabled,
                    onChanged: (value) {
                      context.read<UserBloc>().add(UserEvent.toggleToolUpdate(value));
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
          child: Column(children: children),
        ),
      ],
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
}
