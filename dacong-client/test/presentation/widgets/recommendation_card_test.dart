import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_client/core/domain/entities/recommendation.dart';
import 'package:dacong_client/presentation/widgets/recommendation_card.dart';
import 'package:dacong_client/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  group('RecommendationCard', () {
    const tRecommendation = Recommendation(
      id: '1',
      contentId: 'content-1',
      scenario: 'coding',
      toolName: 'GitHub Copilot',
      description: 'AI编程助手，提供智能代码补全',
      pros: ['智能补全', '上下文理解'],
      cons: ['需要付费'],
      targetAudience: '开发者',
      price: '\$10/月',
      availableInChina: false,
      rating: 4.5,
      rank: 1,
      type: RecommendationType.best,
    );

    Widget createWidgetUnderTest({
      required Recommendation recommendation,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
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
        home: Scaffold(
          body: RecommendationCard(
            recommendation: recommendation,
            onTap: onTap ?? () {},
          ),
        ),
      );
    }

    testWidgets('应该显示工具名称', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        recommendation: tRecommendation,
      ));

      expect(find.text('GitHub Copilot'), findsOneWidget);
    });

    testWidgets('应该显示描述', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        recommendation: tRecommendation,
      ));

      expect(find.text('AI编程助手，提供智能代码补全'), findsOneWidget);
    });

    testWidgets('应该显示评分', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        recommendation: tRecommendation,
      ));

      expect(find.text('4.5'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('应该显示优点列表', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        recommendation: tRecommendation,
      ));

      expect(find.text('• 智能补全'), findsOneWidget);
      expect(find.text('• 上下文理解'), findsOneWidget);
    });

    testWidgets('应该显示缺点列表', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        recommendation: tRecommendation,
      ));

      expect(find.text('• 需要付费'), findsOneWidget);
    });

    testWidgets('应该显示价格', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        recommendation: tRecommendation,
      ));

      expect(find.text('\$10/月'), findsOneWidget);
    });

    testWidgets('国内不可用时应该显示"需翻墙"', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        recommendation: tRecommendation,
      ));

      expect(find.text('需翻墙'), findsOneWidget);
      expect(find.byIcon(Icons.vpn_key), findsOneWidget);
    });

    testWidgets('国内可用时应该显示"国内可用"', (tester) async {
      const availableRecommendation = Recommendation(
        id: '2',
        contentId: 'content-2',
        scenario: 'coding',
        toolName: 'Test Tool',
        description: 'Test',
        pros: [],
        cons: [],
        targetAudience: '开发者',
        price: '免费',
        availableInChina: true,
        rating: 4.0,
        rank: 2,
        type: RecommendationType.free,
      );

      await tester.pumpWidget(createWidgetUnderTest(
        recommendation: availableRecommendation,
      ));

      expect(find.text('国内可用'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('点击卡片时应该触发 onTap 回调', (tester) async {
      var tapped = false;

      await tester.pumpWidget(createWidgetUnderTest(
        recommendation: tRecommendation,
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('最佳推荐应该显示"最佳"标签', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        recommendation: tRecommendation,
      ));

      expect(find.text('最佳'), findsOneWidget);
    });

    testWidgets('平替推荐应该显示"平替"标签', (tester) async {
      const altRecommendation = Recommendation(
        id: '3',
        contentId: 'content-3',
        scenario: 'coding',
        toolName: 'Alternative Tool',
        description: 'Test',
        pros: [],
        cons: [],
        targetAudience: '开发者',
        price: '免费',
        availableInChina: true,
        rating: 4.0,
        rank: 2,
        type: RecommendationType.alternative,
      );

      await tester.pumpWidget(createWidgetUnderTest(
        recommendation: altRecommendation,
      ));

      expect(find.text('平替'), findsOneWidget);
    });

    testWidgets('免费推荐应该显示"免费"标签', (tester) async {
      const freeRecommendation = Recommendation(
        id: '4',
        contentId: 'content-4',
        scenario: 'coding',
        toolName: 'Free Tool',
        description: 'Test',
        pros: [],
        cons: [],
        targetAudience: '开发者',
        price: '免费',
        availableInChina: true,
        rating: 4.0,
        rank: 3,
        type: RecommendationType.free,
      );

      await tester.pumpWidget(createWidgetUnderTest(
        recommendation: freeRecommendation,
      ));

      expect(find.text('免费'), findsOneWidget);
    });
  });
}
