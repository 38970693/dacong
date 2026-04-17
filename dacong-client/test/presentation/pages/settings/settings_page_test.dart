import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dacong_client/core/theme/theme_cubit.dart';
import 'package:dacong_client/presentation/pages/settings/settings_page.dart';

void main() {
  group('SettingsPage', () {
    late ThemeCubit themeCubit;

    setUp(() {
      themeCubit = ThemeCubit();
    });

    tearDown(() {
      themeCubit.close();
    });

    testWidgets('应该显示设置页面标题', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: themeCubit,
            child: const SettingsPage(),
          ),
        ),
      );

      expect(find.text('设置'), findsOneWidget);
    });

    testWidgets('应该显示三个主题选项', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: themeCubit,
            child: const SettingsPage(),
          ),
        ),
      );

      expect(find.text('亮色'), findsOneWidget);
      expect(find.text('暗色'), findsOneWidget);
      expect(find.text('跟随系统'), findsOneWidget);
    });

    testWidgets('点击亮色主题应该切换主题', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: themeCubit,
            child: const SettingsPage(),
          ),
        ),
      );

      await tester.tap(find.text('亮色'));
      await tester.pumpAndSettle();

      expect(themeCubit.state, ThemeMode.light);
    });

    testWidgets('点击暗色主题应该切换主题', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: themeCubit,
            child: const SettingsPage(),
          ),
        ),
      );

      await tester.tap(find.text('暗色'));
      await tester.pumpAndSettle();

      expect(themeCubit.state, ThemeMode.dark);
    });

    testWidgets('选中的主题应该显示选中状态', (WidgetTester tester) async {
      themeCubit.setLightTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: themeCubit,
            child: const SettingsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证选中图标存在
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('主题切换应该有动画效果', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: themeCubit,
            child: const SettingsPage(),
          ),
        ),
      );

      await tester.tap(find.text('亮色'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证动画正在进行
      expect(find.byType(AnimatedContainer), findsWidgets);
    });
  });
}
