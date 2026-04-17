import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dacong_admin/pages/login_page.dart';

void main() {
  group('LoginPage Widget Tests', () {
    testWidgets('should display login form', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // 验证页面元素
      expect(find.text('DaCong 运营后台'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // 邮箱和密码
      expect(find.text('登录'), findsOneWidget);
    });

    testWidgets('should validate email field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // 点击登录按钮（不填写任何内容）
      await tester.tap(find.text('登录'));
      await tester.pump();

      // 应该显示验证错误
      expect(find.text('请输入邮箱'), findsOneWidget);
    });

    testWidgets('should validate password field', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // 只填写邮箱
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );

      // 点击登录按钮
      await tester.tap(find.text('登录'));
      await tester.pump();

      // 应该显示密码验证错误
      expect(find.text('请输入密码'), findsOneWidget);
    });

    testWidgets('should show loading indicator when logging in',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // 填写表单
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );

      // 点击登录按钮
      await tester.tap(find.text('登录'));
      await tester.pump();

      // 应该显示加载指示器
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
