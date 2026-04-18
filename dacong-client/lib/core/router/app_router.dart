// DaCong 路由配置
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../presentation/pages/news/news_page.dart';
import '../../presentation/pages/ranking/ranking_page.dart';
import '../../presentation/pages/empower/empower_page.dart';
import '../../presentation/pages/community/community_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/recommendation_detail/recommendation_detail_page.dart';
import '../../presentation/widgets/common/shell_scaffold.dart';
import '../../presentation/providers/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appRouter = GoRouter(initialLocation: '/', routes: [
  ShellRoute(
    builder: (context, state, child) => ShellScaffold(child: child),
    routes: [
      GoRoute(path: '/',         name: 'news',      pageBuilder: (_, __) => const NoTransitionPage(child: NewsPage())),
      GoRoute(path: '/ranking',  name: 'ranking',   pageBuilder: (_, __) => const NoTransitionPage(child: RankingPage())),
      GoRoute(path: '/empower',  name: 'empower',   pageBuilder: (_, __) => const NoTransitionPage(child: EmpowerPage())),
      GoRoute(path: '/community',name: 'community',  pageBuilder: (_, __) => const NoTransitionPage(child: CommunityPage())),
      GoRoute(path: '/profile',  name: 'profile',   pageBuilder: (_, __) => const NoTransitionPage(child: ProfilePage())),
    ],
  ),
  // 非 Shell 全屏页面
  GoRoute(
    path: '/recommendation/:contentId',
    name: 'recommendationDetail',
    builder: (_, state) => RecommendationDetailPage(
      contentId: state.pathParameters['contentId']!,
    ),
  ),
  GoRoute(path: '/model/:id',    name: 'modelDetail', builder: (_, state) => Scaffold(
    appBar: AppBar(title: const Text('Model')),
    body: Center(child: Text('Model: ${state.pathParameters["id"]}')),
  )),
  GoRoute(path: '/post/:id',    name: 'postDetail', builder: (_, state) => Scaffold(
    appBar: AppBar(title: const Text('Post')),
    body: Center(child: Text('Post: ${state.pathParameters["id"]}')),
  )),
  GoRoute(path: '/lang', name: 'lang', builder: (_, __) => const LanguageSwitchPage()),
  GoRoute(path: '/login', name: 'login', builder: (_, __) => const LoginPage()),
  GoRoute(path: '/create-post', name: 'createPost', builder: (_, __) => const CreatePostPage()),
]);

// ── 简单占位页面 ──────────────────────────────────────

class LanguageSwitchPage extends ConsumerWidget {
  const LanguageSwitchPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeNotifier = ref.watch(localeProvider);
    final current = localeNotifier.locale.languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutApp)),
      body: ListView(
        children: [
          ListTile(
            leading: const Text('🇨🇳', style: TextStyle(fontSize: 28)),
            title: const Text('简体中文'),
            trailing: current == 'zh' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () => localeNotifier.setLocale('zh'),
          ),
          const Divider(),
          ListTile(
            leading: const Text('🇺🇸', style: TextStyle(fontSize: 28)),
            title: const Text('English'),
            trailing: current == 'en' ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () => localeNotifier.setLocale('en'),
          ),
        ],
      ),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sign In')),
    body: const Center(child: Text('Login Page - TODO')),
  );
}

class CreatePostPage extends StatelessWidget {
  const CreatePostPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Post')),
    body: const Center(child: Text('Create Post - TODO')),
  );
}
