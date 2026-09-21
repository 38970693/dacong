import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/sentry_config.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/error/error_boundary.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'l10n/app_localizations.dart';
import 'presentation/pages/home/home_page.dart';
import 'presentation/pages/settings/settings_page.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/register_page.dart';
import 'presentation/pages/auth/reset_password_page.dart';
import 'presentation/pages/user/profile_edit_page.dart';
import 'presentation/pages/ranking/ranking_page.dart';
import 'presentation/pages/model_detail/model_detail_page.dart';
import 'presentation/pages/model_compare/model_compare_page.dart';

void main() async {
  // 初始化 Sentry 并运行应用
  await SentryConfig.init(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 初始化异步错误处理
    AsyncErrorHandler.init();

    // 初始化 Supabase
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );

    // 配置依赖注入
    configureDependencies();

    // 设置应用标签
    SentryConfig.setTag('platform', 'flutter');
    SentryConfig.setTag('app', 'dacong-client');

    runApp(const ErrorBoundary(child: DaCongApp()));
  });
}

class DaCongApp extends StatelessWidget {
  const DaCongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ThemeCubit()..loadTheme(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: AppConstants.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('zh'),
              Locale('en'),
            ],
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

// 路由配置
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/content/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return Scaffold(
          appBar: AppBar(title: const Text('内容详情')),
          body: Center(child: Text('内容 ID: $id')),
        );
      },
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('搜索')),
        body: const Center(child: Text('搜索页面')),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    // 认证路由
    GoRoute(
      path: '/auth/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/auth/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/auth/reset-password',
      builder: (context, state) => const ResetPasswordPage(),
    ),
    // 用户路由
    GoRoute(
      path: '/user/profile/edit',
      builder: (context, state) => const ProfileEditPage(),
    ),
    // 数据底座：模型排行 / 模型详情 / 能力对比
    GoRoute(
      path: '/ranking',
      builder: (context, state) => const RankingPage(),
    ),
    GoRoute(
      path: '/model/:id',
      builder: (context, state) =>
          ModelDetailPage(modelId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/compare',
      builder: (context, state) => ModelComparePage(
        initialIds: (state.uri.queryParameters['ids'] ?? '')
            .split(',')
            .where((id) => id.isNotEmpty)
            .toList(),
      ),
    ),
  ],
);
