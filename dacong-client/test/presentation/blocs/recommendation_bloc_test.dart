import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:dacong_client/core/domain/entities/recommendation.dart';
import 'package:dacong_client/core/domain/usecases/get_recommendations.dart';
import 'package:dacong_client/core/error/failures.dart';
import 'package:dacong_client/presentation/blocs/recommendation/recommendation_bloc.dart';

import 'recommendation_bloc_test.mocks.dart';

@GenerateMocks([GetRecommendations])
void main() {
  late RecommendationBloc bloc;
  late MockGetRecommendations mockGetRecommendations;

  setUp(() {
    mockGetRecommendations = MockGetRecommendations();
    bloc = RecommendationBloc(mockGetRecommendations);
  });

  tearDown(() {
    bloc.close();
  });

  group('RecommendationBloc', () {
    const tScenario = 'coding';
    final tRecommendations = [
      const Recommendation(
        id: '1',
        contentId: 'content-1',
        scenario: 'coding',
        toolName: 'GitHub Copilot',
        description: 'AI编程助手',
        pros: ['智能补全', '上下文理解'],
        cons: ['需要付费'],
        targetAudience: '开发者',
        price: '\$10/月',
        availableInChina: false,
        rating: 4.5,
        rank: 1,
        type: RecommendationType.best,
      ),
    ];

    test('初始状态应该是 RecommendationInitial', () {
      expect(bloc.state, equals(RecommendationInitial()));
    });

    blocTest<RecommendationBloc, RecommendationState>(
      '加载推荐成功时应该发出 [Loading, Loaded]',
      build: () {
        when(mockGetRecommendations(any))
            .thenAnswer((_) async => Right(tRecommendations));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadRecommendations(tScenario)),
      expect: () => [
        RecommendationLoading(),
        RecommendationLoaded(tRecommendations),
      ],
      verify: (_) {
        verify(mockGetRecommendations(tScenario));
      },
    );

    blocTest<RecommendationBloc, RecommendationState>(
      '加载推荐失败时应该发出 [Loading, Error]',
      build: () {
        when(mockGetRecommendations(any))
            .thenAnswer((_) async => const Left(ServerFailure('服务器错误')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadRecommendations(tScenario)),
      expect: () => [
        RecommendationLoading(),
        const RecommendationError('服务器错误'),
      ],
      verify: (_) {
        verify(mockGetRecommendations(tScenario));
      },
    );

    blocTest<RecommendationBloc, RecommendationState>(
      '刷新推荐成功时应该发出 [Loaded]',
      build: () {
        when(mockGetRecommendations(any))
            .thenAnswer((_) async => Right(tRecommendations));
        return bloc;
      },
      act: (bloc) => bloc.add(const RefreshRecommendations(tScenario)),
      expect: () => [
        RecommendationLoaded(tRecommendations),
      ],
      verify: (_) {
        verify(mockGetRecommendations(tScenario));
      },
    );

    blocTest<RecommendationBloc, RecommendationState>(
      '加载更多推荐时应该合并数据',
      build: () {
        when(mockGetRecommendations(any))
            .thenAnswer((_) async => Right(tRecommendations));
        return bloc;
      },
      seed: () => RecommendationLoaded(tRecommendations),
      act: (bloc) => bloc.add(const LoadMoreRecommendations(tScenario)),
      expect: () => [
        RecommendationLoaded(
          tRecommendations,
          hasMore: true,
          isLoadingMore: true,
        ),
        RecommendationLoaded(
          [...tRecommendations, ...tRecommendations],
          hasMore: true,
          isLoadingMore: false,
        ),
      ],
      verify: (_) {
        verify(mockGetRecommendations(tScenario));
      },
    );

    blocTest<RecommendationBloc, RecommendationState>(
      '网络错误时应该返回网络错误消息',
      build: () {
        when(mockGetRecommendations(any))
            .thenAnswer((_) async => const Left(NetworkFailure('网络连接失败')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadRecommendations(tScenario)),
      expect: () => [
        RecommendationLoading(),
        const RecommendationError('网络连接失败'),
      ],
    );
  });
}
