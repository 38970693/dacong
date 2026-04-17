// Shell Scaffold - 底部导航 + AppBar 封装
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';

class ShellScaffold extends StatelessWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: kIsWeb
            ? [
                IconButton(
                  icon: const Icon(Icons.language),
                  tooltip: 'Switch Language',
                  onPressed: () => context.push('/lang'),
                ),
              ]
            : null,
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(context, index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.flash_on_outlined),
            selectedIcon: const Icon(Icons.flash_on),
            label: l10n.newsTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.leaderboard_outlined),
            selectedIcon: const Icon(Icons.leaderboard),
            label: l10n.rankingTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.card_giftcard_outlined),
            selectedIcon: const Icon(Icons.card_giftcard),
            label: l10n.empowerTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outlined),
            selectedIcon: const Icon(Icons.people),
            label: l10n.communityTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person),
            label: l10n.profileTab,
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/ranking')) return 1;
    if (location.startsWith('/empower')) return 2;
    if (location.startsWith('/community')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/ranking');
        break;
      case 2:
        context.go('/empower');
        break;
      case 3:
        context.go('/community');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}
