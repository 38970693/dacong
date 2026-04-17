import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:dacong_client/core/domain/entities/weekly.dart';
import 'package:dacong_client/core/domain/usecases/get_weekly_report.dart';
import 'package:dacong_client/core/error/failures.dart';
import 'package:dacong_client/presentation/blocs/weekly/weekly_bloc.dart';

@GenerateMocks([GetWeeklyReport])
import 'weekly_bloc_test.mocks.dart';

void main() {
  late WeeklyBloc bloc;
  late MockGetWeeklyReport mockGetWeeklyReport;

  setUp(() {
    mockGetWeeklyReport = MockGetWeeklyReport();
    bloc = WeeklyBloc(mockGetWeeklyReport);
  });

  tearDown(() {
    bloc.close();
  });

  group('WeeklyBloc', () {
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

    final tWeeklyList = [tWeekly];

    test('初始状态应该是 WeeklyInitial', () {
      expect(bloc.state, equals(WeeklyInitial()));
    });

    group('LoadWeekly', () {
      blocTest<WeeklyBloc, WeeklyState>(
        '成功加载周报时应该发出 [WeeklyLoading, WeeklyLoaded]',
        build: () {
          when(mockGetWeeklyReport.call())
              .thenAnswer((_) async => Right(tWeekly));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadWeekly()),
        expect: () => [
          WeeklyLoading(),
          WeeklyLoaded(tWeekly),
        ],
        verify: (_) {
          verify(mockGetWeeklyReport.call());
        },
      );

      blocTest<WeeklyBloc, WeeklyState>(
        '加载失败时应该发出 [WeeklyLoading, WeeklyError]',
        build: () {
          when(mockGetWeeklyReport.call()).thenAnswer(
            (_) async => Left(ServerFailure('服务器错误')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadWeekly()),
        expect: () => [
          WeeklyLoading(),
          const WeeklyError('服务器错误'),
        ],
        verify: (_) {
          verify(mockGetWeeklyReport.call());
        },
      );

      blocTest<WeeklyBloc, WeeklyState>(
        '网络错误时应该发出正确的错误消息',
        build: () {
          when(mockGetWeeklyReport.call()).thenAnswer(
            (_) async => Left(NetworkFailure('网络连接失败')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadWeekly()),
        expect: () => [
          WeeklyLoading(),
          const WeeklyError('网络连接失败'),
        ],
      );
    });

    group('LoadWeeklyHistory', () {
      blocTest<WeeklyBloc, WeeklyState>(
        '成功加载历史周报时应该发出 [WeeklyLoading, WeeklyHistoryLoaded]',
        build: () {
          when(mockGetWeeklyReport.getHistory(limit: 10))
              .thenAnswer((_) async => Right(tWeeklyList));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadWeeklyHistory(limit: 10)),
        expect: () => [
          WeeklyLoading(),
          WeeklyHistoryLoaded(tWeeklyList),
        ],
        verify: (_) {
          verify(mockGetWeeklyReport.getHistory(limit: 10));
        },
      );

      blocTest<WeeklyBloc, WeeklyState>(
        '加载历史周报失败时应该发出错误',
        build: () {
          when(mockGetWeeklyReport.getHistory(limit: 10)).thenAnswer(
            (_) async => Left(ServerFailure('服务器错误')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadWeeklyHistory(limit: 10)),
        expect: () => [
          WeeklyLoading(),
          const WeeklyError('服务器错误'),
        ],
      );
    });

    group('ShareWeekly', () {
      blocTest<WeeklyBloc, WeeklyState>(
        '分享周报时应该发出 [WeeklySharing, WeeklyShared, WeeklyLoaded]',
        build: () => bloc,
        seed: () => WeeklyLoaded(tWeekly),
        act: (bloc) => bloc.add(const ShareWeekly('1')),
        expect: () => [
          WeeklySharing(tWeekly),
          WeeklyShared(tWeekly),
          WeeklyLoaded(tWeekly),
        ],
      );

      blocTest<WeeklyBloc, WeeklyState>(
        '非 WeeklyLoaded 状态时分享不应该改变状态',
        build: () => bloc,
        seed: () => WeeklyLoading(),
        act: (bloc) => bloc.add(const ShareWeekly('1')),
        expect: () => [],
      );
    });
  });
}
