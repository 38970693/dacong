import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dacong_client/core/domain/entities/content.dart';
import 'package:dacong_client/core/domain/entities/recommendation.dart';
import 'package:dacong_client/core/error/exceptions.dart';
import 'package:dacong_client/core/error/failures.dart';
import 'package:dacong_client/data/datasources/remote_data_source.dart';
import 'package:dacong_client/data/models/content_model.dart';
import 'package:dacong_client/data/models/recommendation_model.dart';
import 'package:dacong_client/data/repositories/content_repository_impl.dart';

class MockRemoteDataSource extends Mock implements RemoteDataSource {}

void main() {
  late ContentRepositoryImpl repository;
  late MockRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockRemoteDataSource();
    repository = ContentRepositoryImpl(mockRemoteDataSource);
  });

  group('ContentRepositoryImpl', () {
    const tScenario = 'coding';
    const tContentId = 'content-1';

    final tRecommendationModel = RecommendationModel(
      id: '1',
      contentId: 'content-1',
      scenario: 'coding',
      toolName: 'GitHub Copilot',
      description: 'AI编程助手',
      pros: const ['智能补全'],
      cons: const ['需要付费'],
      targetAudience: '开发者',
      price: '\$10/月',
      availableInChina: false,
      rating: 4.5,
      rank: 1,
      type: 'best',
    );

    final tContentModel = ContentModel(
      id: 'content-1',
      name: 'Test Tool',
      vendor: 'Test Vendor',
      description: 'Test Description',
      features: const ['feature1', 'feature2'],
      priceInfo: const PriceInfoModel(isFree: true),
      accessInfo: const AccessInfoModel(
        availableInChina: true,
        needsVpn: false,
        difficulty: 'easy',
      ),
      useCases: const ['use-case-1'],
      publishedAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    group('getRecommendationsByScenario', () {
      test('returns recommendations when call succeeds', () async {
        when(() => mockRemoteDataSource.getRecommendationsByScenario(tScenario))
            .thenAnswer((_) async => [tRecommendationModel]);

        final result = await repository.getRecommendationsByScenario(tScenario);

        expect(result, isA<Right<Failure, List<Recommendation>>>());
        result.fold(
          (failure) => fail('Should return Right'),
          (recommendations) {
            expect(recommendations, hasLength(1));
            expect(recommendations.first.toolName, 'GitHub Copilot');
          },
        );
        verify(() => mockRemoteDataSource.getRecommendationsByScenario(tScenario))
            .called(1);
      });

      test('returns ServerFailure when ServerException is thrown', () async {
        when(() => mockRemoteDataSource.getRecommendationsByScenario(tScenario))
            .thenThrow(const ServerException('Server error'));

        final result = await repository.getRecommendationsByScenario(tScenario);

        expect(result, isA<Left<Failure, List<Recommendation>>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, 'Server error');
          },
          (recommendations) => fail('Should return Left'),
        );
      });

      test('returns NetworkFailure when NetworkException is thrown', () async {
        when(() => mockRemoteDataSource.getRecommendationsByScenario(tScenario))
            .thenThrow(const NetworkException('Network error'));

        final result = await repository.getRecommendationsByScenario(tScenario);

        expect(result, isA<Left<Failure, List<Recommendation>>>());
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.message, 'Network error');
          },
          (recommendations) => fail('Should return Left'),
        );
      });

      test('returns ServerFailure when unknown exception is thrown', () async {
        when(() => mockRemoteDataSource.getRecommendationsByScenario(tScenario))
            .thenThrow(Exception('Unknown error'));

        final result = await repository.getRecommendationsByScenario(tScenario);

        expect(result, isA<Left<Failure, List<Recommendation>>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, contains('未知错误'));
          },
          (recommendations) => fail('Should return Left'),
        );
      });
    });

    group('getContentById', () {
      test('returns content when call succeeds', () async {
        when(() => mockRemoteDataSource.getContentById(tContentId))
            .thenAnswer((_) async => tContentModel);

        final result = await repository.getContentById(tContentId);

        expect(result, isA<Right<Failure, Content>>());
        result.fold(
          (failure) => fail('Should return Right'),
          (content) {
            expect(content.id, 'content-1');
            expect(content.name, 'Test Tool');
          },
        );
        verify(() => mockRemoteDataSource.getContentById(tContentId)).called(1);
      });

      test('returns ServerFailure when ServerException is thrown', () async {
        when(() => mockRemoteDataSource.getContentById(tContentId))
            .thenThrow(const ServerException('Content not found'));

        final result = await repository.getContentById(tContentId);

        expect(result, isA<Left<Failure, Content>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, 'Content not found');
          },
          (content) => fail('Should return Left'),
        );
      });
    });

    group('searchContent', () {
      const tQuery = 'AI tools';

      test('returns search results when call succeeds', () async {
        when(() => mockRemoteDataSource.searchContent(
              tQuery,
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              scenario: any(named: 'scenario'),
              isFree: any(named: 'isFree'),
              availableInChina: any(named: 'availableInChina'),
              sortBy: any(named: 'sortBy'),
            )).thenAnswer((_) async => [tContentModel]);

        final result = await repository.searchContent(tQuery);

        expect(result, isA<Right<Failure, List<Content>>>());
        result.fold(
          (failure) => fail('Should return Right'),
          (contents) {
            expect(contents, hasLength(1));
            expect(contents.first.name, 'Test Tool');
          },
        );
      });

      test('returns NetworkFailure when NetworkException is thrown', () async {
        when(() => mockRemoteDataSource.searchContent(
              tQuery,
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
              scenario: any(named: 'scenario'),
              isFree: any(named: 'isFree'),
              availableInChina: any(named: 'availableInChina'),
              sortBy: any(named: 'sortBy'),
            )).thenThrow(const NetworkException('No internet'));

        final result = await repository.searchContent(tQuery);

        expect(result, isA<Left<Failure, List<Content>>>());
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.message, 'No internet');
          },
          (contents) => fail('Should return Left'),
        );
      });
    });

    group('getRelatedContent', () {
      test('returns related content when call succeeds', () async {
        when(() => mockRemoteDataSource.getRelatedContent(
              tContentId,
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => [tContentModel]);

        final result = await repository.getRelatedContent(tContentId);

        expect(result, isA<Right<Failure, List<Content>>>());
        result.fold(
          (failure) => fail('Should return Right'),
          (contents) {
            expect(contents, hasLength(1));
          },
        );
        verify(() => mockRemoteDataSource.getRelatedContent(
              tContentId,
              limit: any(named: 'limit'),
            )).called(1);
      });

      test('returns ServerFailure when ServerException is thrown', () async {
        when(() => mockRemoteDataSource.getRelatedContent(
              tContentId,
              limit: any(named: 'limit'),
            )).thenThrow(const ServerException('Failed to fetch'));

        final result = await repository.getRelatedContent(tContentId);

        expect(result, isA<Left<Failure, List<Content>>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
          },
          (contents) => fail('Should return Left'),
        );
      });
    });
  });
}
