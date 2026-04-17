import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dacong_client/presentation/widgets/scenario_selector.dart';
import 'package:dacong_client/l10n/app_localizations.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
      home: Scaffold(body: child),
    );
  }

  testWidgets('ScenarioSelector displays all scenarios', (tester) async {
    String? selectedScenario;

    await tester.pumpWidget(
      createTestWidget(
        ScenarioSelector(
          selectedScenario: selectedScenario,
          onScenarioSelected: (scenario) {
            selectedScenario = scenario;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 验证标题
    expect(find.text('选择使用场景'), findsOneWidget);

    // 验证所有场景卡片
    expect(find.text('写代码'), findsOneWidget);
    expect(find.text('做视频'), findsOneWidget);
    expect(find.text('做图片'), findsOneWidget);
    expect(find.text('日常对话'), findsOneWidget);
  });

  testWidgets('ScenarioSelector handles selection', (tester) async {
    String? selectedScenario;

    await tester.pumpWidget(
      createTestWidget(
        ScenarioSelector(
          selectedScenario: selectedScenario,
          onScenarioSelected: (scenario) {
            selectedScenario = scenario;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 点击"写代码"场景
    await tester.tap(find.text('写代码'));
    await tester.pumpAndSettle();

    // 验证回调被调用
    expect(selectedScenario, equals('coding'));
  });

  testWidgets('ScenarioSelector highlights selected scenario', (tester) async {
    await tester.pumpWidget(
      createTestWidget(
        ScenarioSelector(
          selectedScenario: 'video',
          onScenarioSelected: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 验证选中状态
    expect(find.text('做视频'), findsOneWidget);
  });
}
