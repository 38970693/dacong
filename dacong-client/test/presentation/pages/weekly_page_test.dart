import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:dacong_client/core/domain/entities/weekly.dart';
import 'package:dacong_client/presentation/blocs/weekly/weekly_bloc.dart';
import 'package:dacong_client/presentation/pages/weekly/weekly_page.dart';

@GenerateMocks([WeeklyBloc])
import 'weekly_page_test.mocks.dart';

void main() {
  late MockWeeklyBloc mockWeeklyBloc;

  setUp(() {
    mockWeeklyBloc = MockWeeklyBloc();
  });

  Widget makeTestableWidget(Widget body) {
    return BlocProvider<WeeklyBloc>.value(
      value: mockWeeklyBloc,
      child: MaterialApp(
        home: body,
      ),
    );
  }

  final tWeekly = Weekly(
    id: '1',
    title: '本周 AI 工具精选',
    summary: '本周最值得关注的 AI 项目',
    weekStart: '2026-04-14',
    weekEnd: '2026-04-20',
    sections: [
      WeeklySection(
        sectionTitle: '本周最火',
        items: [
          WeeklyItem(
            name: 'DeepSeek-V3',
            oneLiner: '强大的开源大模型',
            whyMatters: '性能超越 GPT-4',
            githubUrl: 'https://github.com/deepseek-ai/DeepSeek-V3',
            stars: 15000,
            starGrowth: 5000,
            access: '国内可用',
          ),
        ],
      ),
    ],
    viewCount: 1000,
    helpfulCount: 800,
    publishedAt: DateTime(2026, 4, 20),
    helpfulRate: 0.8,
  );

  group('WeeklyPage', () {
    testWidgets('应该显示 AppBar 标题', (tester) async {
      when(mockWeeklyBloc.state).thenReturn(WeeklyInitial());
      when(mockWeeklyBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(makeTestableWidget(const WeeklyPage()));

      expect(find.text('本周精选'), findsOneWidget);
    });

    testWidgets('应该显示历史按钮', (tester) async {
      when(mockWeeklyBloc.state).thenReturn(WeeklyInitial());
      when(mockWeeklyBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(makeTestableWidget(const WeeklyPage()));

      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('WeeklyLoading 状态时应该显示加载指示器', (tester) async {
      when(mockWeeklyBloc.state).thenReturn(WeeklyLoading());
      when(mockWeeklyBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(makeTestableWidget(const WeeklyPage()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('WeeklyError 状态时应该显示错误消息', (tester) async {
      when(mockWeeklyBloc.state).thenReturn(const WeeklyError('测试错误'));
      when(mockWeeklyBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(makeTestableWidget(const WeeklyPage()));

      expect(find.text('测试错误'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('点击重试按钮应该触发 LoadWeekly 事件', (tester) async {
      when(mockWeeklyBloc.state).thenReturn(const WeeklyError('测试错误'));
      when(mockWeeklyBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(makeTestableWidget(const WeeklyPage()));

      await tester.tap(find.text('重试'));
      await tester.pump();

      verify(mockWeeklyBloc.add(const LoadWeekly())).called(1);
    });

    testWidgets('WeeklyLoaded 状态时应该显示周报内容', (tester) async {
      when(mockWeeklyBloc.state).thenReturn(WeeklyLoaded(tWeekly));
      when(mockWeeklyBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(makeTestableWidget(const WeeklyPage()));

      expect(find.text('本周 AI 工具精选'), findsOneWidget);
      expect(find.text('2026-04-14 - 2026-04-20'), findsOneWidget);
      expect(find.text('本周最值得关注的 AI 项目'), findsOneWidget);
    });

    testWidgets('应该显示周报板块', (tester) async {
      when(mockWeeklyBloc.state).thenReturn(WeeklyLoaded(tWeekly));
      when(mockWeeklyBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(makeTestableWidget(const WeeklyPage()));

      expect(find.text('本周最火'), findsOneWidget);
    });

    testWidgets('应该显示周报项目', (tester) async {
      when(mockWeeklyBloc.state).thenReturn(WeeklyLoaded(tWeekly));
      when(mockWeeklyBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(makeTestableWidget(const WeeklyPage()));

      expect(find.text('DeepSeek-V3'), findsOneWidget);
      expect(find.text('强大的开源大模型'), findsOneWidget);
      expect(find.text('性能超越 GPT-4'), findsOneWidget);
      expect(find.text('国内可用'), findsOneWidget);
    });

    testWidgets('应该显示 Star 数和增长', (tester) async {
      when(mockWeeklyBloc.state).thenReturn(WeeklyLoaded(tWeekly));
      when(mockWeeklyBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(makeTestableWidget(const WeeklyPage()));

      expect(find.text('15.0k stars'), findsOneWidget);
      expect(find.text('+5.0k'), findsOneWidget);
    });

    testWidgets('应该显示分享按钮', (tester) async {
      when(mockWeeklyBloc.state).thenReturn(WeeklyLoaded(tWeekly));
      when(mockWeeklyBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(makeTestableWidget(const WeeklyPage()));

      expect(find.text('分享周报'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('点击分享按钮应该触发 ShareWeekly 事件', (tester) async {
      when(mockWeeklyBloc.state).thenReturn(WeeklyLoaded(tWeekly));
      when(mockWeeklyBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(makeTestableWidget(const WeeklyPage()));

      await tester.tap(find.text('分享周报'));
      await tester.pump();

      verify(mockWeeklyBloc.add(const ShareWeekly('1'))).called(1);
    });

    testWidgets('点击历史按钮应该触发 LoadWeeklyHistory 事件', (tester) async {
      when(mockWeeklyBloc.state).thenReturn(WeeklyInitial());
      when(mockWeeklyBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(makeTestableWidget(const WeeklyPage()));

      await tester.tap(find.byIcon(Icons.history));
      await tester.pump();

      verify(mockWeeklyBloc.add(const LoadWeeklyHistory())).called(1);
    });

    testWidgets('WeeklyHistoryLoaded 状态时应该显示历史列表', (tester) async {
      when(mockWeeklyBloc.state).thenReturn(WeeklyHistoryLoaded([tWeekly]));
      when(mockWeeklyBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(makeTestableWidget(const WeeklyPage()));

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('本周 AI 工具精选'), findsOneWidget);
    });

    testWidgets('应该显示统计信息', (tester) async {
      when(mockWeeklyBloc.state).thenReturn(WeeklyLoaded(tWeekly));
      when(mockWeeklyBloc.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(makeTestableWidget(const WeeklyPage()));

      expect(find.text('1000 阅读'), findsOneWidget);
      expect(find.text('800 有用'), findsOneWidget);
    });
  });
}
