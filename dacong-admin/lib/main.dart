import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/sentry_config.dart';
import 'core/error/error_boundary.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/content_management_page.dart';
import 'pages/user_management_page.dart';
import 'pages/comment_moderation_page.dart';
import 'pages/analytics_page.dart';

void main() async {
  // 初始化 Sentry 并运行应用
  await SentryConfig.init(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 初始化异步错误处理
    AsyncErrorHandler.init();

    // 初始化 Supabase
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    );

    // 设置应用标签
    SentryConfig.setTag('platform', 'flutter');
    SentryConfig.setTag('app', 'dacong-admin');

    runApp(const ProviderScope(
      child: ErrorBoundary(child: DaCongAdminApp()),
    ));
  });
}

class DaCongAdminApp extends StatelessWidget {
  const DaCongAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'DaCong 运营后台',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

// 路由配置
final _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    final isLoginPage = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoginPage) {
      return '/login';
    }
    if (isLoggedIn && isLoginPage) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/content',
          builder: (context, state) => const ContentManagementPage(),
        ),
        GoRoute(
          path: '/users',
          builder: (context, state) => const UserManagementPage(),
        ),
        GoRoute(
          path: '/comments',
          builder: (context, state) => const CommentModerationPage(),
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsPage(),
        ),
      ],
    ),
  ],
);

// 后台Shell（侧边栏布局）
class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 侧边栏
          NavigationRail(
            extended: true,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('数据看板'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.article),
                label: Text('内容管理'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('用户管理'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.comment),
                label: Text('评论审核'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics),
                label: Text('数据分析'),
              ),
            ],
            selectedIndex: _getSelectedIndex(context),
            onDestinationSelected: (index) => _onDestinationSelected(context, index),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // 主内容区
          Expanded(child: child),
        ],
      ),
    );
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location.startsWith('/content')) return 1;
    if (location.startsWith('/users')) return 2;
    if (location.startsWith('/comments')) return 3;
    if (location.startsWith('/analytics')) return 4;
    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/content');
        break;
      case 2:
        context.go('/users');
        break;
      case 3:
        context.go('/comments');
        break;
      case 4:
        context.go('/analytics');
        break;
    }
  }
}
