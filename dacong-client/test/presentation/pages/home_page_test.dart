import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:dacong_client/core/domain/entities/recommendation.dart';
import 'package:dacong_client/presentation/blocs/recommendation/recommendation_bloc.dart';
import 'package:dacong_client/presentation/pages/home/home_page.dart';
import 'package:dacong_client/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'home_page_test.mocks.dart';

@GenerateMocks([RecommendationBloc])
void main() {
  late MockRecommendationBloc mockBloc;

  setUp(() {
    mockBloc = MockRecommendationBloc();
  });

  Widget createWidgetUnderTest() {
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
      home: BlocProvider<RecommendationBloc>.value(
        value: mockBloc,
        child: const Scaffold(
          body: HomePage(),
        ),
      ),
    );
  }

  group('HomePage', () {
    testWidgets('应该显示场景选择器', (tester) async {
      when(mockBloc.state).thenReturn(RecommendationInitial());
      when(mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('选择使用场景'), findsOneWidget);
    });

    testWidgets('初始状态应该显示提示文本', (tester) async {
      when(mockBloc.state).thenReturn(RecommendationInitial());
      when(mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('请选择一个使用场景'), findsOneWidget);
    });

    testWidgets('加载中状态应该显示进度指示器', (tester) async {
      when(mockBloc.state).thenReturn(RecommendationLoading());
      when(mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('加载成功应该显示推荐列表', (tester) async {
      final recommendations = [
        const Recommendation(
          id: '1',
          contentId: 'content-1',
          scenario: 'coding',
          toolName: 'GitHub Copilot',
          description: 'AI编程助手',
          pros: ['智能补全'],
          cons: ['需要付费'],
          targetAudience: '开发者',
          price: '\$10/月',
          availableInChina: false,
          rating: 4.5,
          rank: 1,
          type: RecommendationType.best,
        ),
      ];

      when(mockBloc.state).thenReturn(RecommendationLoaded(recommendations));
      when(mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('GitHub Copilot'), findsOneWidget);
    });

    testWidgets('空列表应该显示"暂无推荐"', (tester) async {
      when(mockBloc.state).thenReturn(const RecommendationLoaded([]));
      when(mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('暂无推荐'), findsOneWidget);
    });

    testWidgets('错误状态应该显示错误信息和重试按钮', (tester) async {
      when(mockBloc.state).thenReturn(const RecommendationError('网络错误'));
      when(mockBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('网络错误'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('下拉刷新应该触发刷新事件', (tester) async {
      final recommendations = [
        const Recommendation(
          id: '1',
          contentId: 'content-1',
          scenario: 'coding',
          toolName: 'Test Tool',
          description: 'Test',
          pros: [],
          cons: [],
          targetAudience: '开发者',
          price: '免费',
          availableInChina: true,
          rating: 4.0,
          rank: 1,
          type: RecommendationType.free,
        ),
      ];

      whenListen(
        mockBloc,
        Stream.fromIterable([
          RecommendationLoaded(recommendations),
        ]),
        initialState: RecommendationLoaded(recommendations),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 模拟下拉刷新
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();

      // 验证刷新事件被触发
      verify(mockBloc.add(any)).called(greaterThan(0));
    });
  });
}
