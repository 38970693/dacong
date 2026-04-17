import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dacong_client/core/domain/entities/content.dart';
import 'package:dacong_client/core/domain/entities/feedback.dart';
import 'package:dacong_client/core/domain/usecases/get_content_detail.dart';
import 'package:dacong_client/core/domain/usecases/submit_feedback.dart';
import 'package:dacong_client/core/domain/repositories/i_content_repository.dart';
import 'package:dacong_client/core/domain/repositories/i_feedback_repository.dart';
import 'package:dacong_client/core/error/failures.dart';
import 'package:dacong_client/presentation/blocs/content_detail/content_detail_bloc.dart';
import 'package:dacong_client/presentation/blocs/content_detail/content_detail_event.dart';
import 'package:dacong_client/presentation/blocs/content_detail/content_detail_state.dart';

@GenerateMocks([
  GetContentDetail,
  SubmitFeedback,
  IContentRepository,
  IFeedbackRepository,
])
import 'content_detail_bloc_test.mocks.dart';

void main() {
  late ContentDetailBloc bloc;
  late MockGetContentDetail mockGetContentDetail;
  late MockSubmitFeedback mockSubmitFeedback;
  late MockIContentRepository mockContentRepository;
  late MockIFeedbackRepository mockFeedbackRepository;

  setUp(() {
    mockGetContentDetail = MockGetContentDetail();
    mockSubmitFeedback = MockSubmitFeedback();
    mockContentRepository = MockIContentRepository();
    mockFeedbackRepository = MockIFeedbackRepository();

    bloc = ContentDetailBloc(
      mockGetContentDetail,
      mockSubmitFeedback,
      mockContentRepository,
      mockFeedbackRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('ContentDetailBloc', () {
    const testContentId = 'test-content-id';

    final testContent = Content(
      id: testContentId,
      name: 'Test Tool',
      vendor: 'Test Vendor',
      description: 'Test Description',
      officialWebsite: 'https://test.com',
      githubUrl: 'https://github.com/test',
      features: ['Feature 1', 'Feature 2'],
      priceInfo: const PriceInfo(
        isFree: true,
        freeDescription: 'Free forever',
        paidDescription: null,
        tiers: [],
      ),
      accessInfo: const AccessInfo(
        availableInChina: true,
        needsVpn: false,
        difficulty: InstallDifficulty.easy,
        installGuideUrl: 'https://test.com/guide',
      ),
      useCases: ['Use case 1', 'Use case 2'],
      helpfulCount: 10,
      unhelpfulCount: 2,
      publishedAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    final testRelatedContent = [
      testContent.copyWith(id: 'related-1', name: 'Related Tool 1'),
      testContent.copyWith(id: 'related-2', name: 'Related Tool 2'),
    ];

    final testFeedback = UserFeedback(
      id: 'feedback-1',
      contentId: testContentId,
      userId: 'user-1',
      type: FeedbackType.helpful,
      comment: null,
      createdAt: DateTime(2024, 1, 1),
    );

    test('initial state is ContentDetailInitial', () {
      expect(bloc.state, equals(const ContentDetailState.initial()));
    });

    group('LoadContentDetail', () {
      blocTest<ContentDetailBloc, ContentDetailState>(
        'emits [loading, loaded] when content is loaded successfully',
        build: () {
          when(mockGetContentDetail(testContentId))
              .thenAnswer((_) async => Right(testContent));
          when(mockContentRepository.getRelatedContent(testContentId, limit: 3))
              .thenAnswer((_) async => Right(testRelatedContent));
          when(mockFeedbackRepository.getUserFeedback(testContentId))
              .thenAnswer((_) async => const Right(null));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const ContentDetailEvent.loadContentDetail(testContentId),
        ),
        expect: () => [
          const ContentDetailState.loading(),
          ContentDetailState.loaded(
            content: testContent,
            relatedContent: testRelatedContent,
            userFeedback: null,
            isFavorite: false,
          ),
        ],
        verify: (_) {
          verify(mockGetContentDetail(testContentId)).called(1);
          verify(mockContentRepository.getRelatedContent(testContentId, limit: 3))
              .called(1);
          verify(mockFeedbackRepository.getUserFeedback(testContentId)).called(1);
        },
      );

      blocTest<ContentDetailBloc, ContentDetailState>(
        'emits [loading, error] when content loading fails',
        build: () {
          when(mockGetContentDetail(testContentId))
              .thenAnswer((_) async => Left(ServerFailure('Server error')));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const ContentDetailEvent.loadContentDetail(testContentId),
        ),
        expect: () => [
          const ContentDetailState.loading(),
          const ContentDetailState.error('Server error'),
        ],
      );
    });

    group('SubmitFeedback', () {
      blocTest<ContentDetailBloc, ContentDetailState>(
        'emits [submittingFeedback, feedbackSubmitted, loaded] when feedback is submitted successfully',
        build: () {
          when(mockSubmitFeedback(
            contentId: testContentId,
            type: FeedbackType.helpful,
            comment: null,
          )).thenAnswer((_) async => Right(testFeedback));
          return bloc;
        },
        seed: () => ContentDetailState.loaded(
          content: testContent,
          relatedContent: testRelatedContent,
          userFeedback: null,
          isFavorite: false,
        ),
        act: (bloc) => bloc.add(
          const ContentDetailEvent.submitFeedback(
            contentId: testContentId,
            type: FeedbackType.helpful,
          ),
        ),
        expect: () => [
          ContentDetailState.submittingFeedback(
            content: testContent,
            relatedContent: testRelatedContent,
            userFeedback: null,
            isFavorite: false,
          ),
          ContentDetailState.feedbackSubmitted(
            content: testContent.copyWith(helpfulCount: 11),
            relatedContent: testRelatedContent,
            userFeedback: testFeedback,
            isFavorite: false,
          ),
        ],
        verify: (_) {
          verify(mockSubmitFeedback(
            contentId: testContentId,
            type: FeedbackType.helpful,
            comment: null,
          )).called(1);
        },
      );

      blocTest<ContentDetailBloc, ContentDetailState>(
        'emits error when feedback submission fails',
        build: () {
          when(mockSubmitFeedback(
            contentId: testContentId,
            type: FeedbackType.helpful,
            comment: null,
          )).thenAnswer((_) async => Left(ServerFailure('Failed to submit')));
          return bloc;
        },
        seed: () => ContentDetailState.loaded(
          content: testContent,
          relatedContent: testRelatedContent,
          userFeedback: null,
          isFavorite: false,
        ),
        act: (bloc) => bloc.add(
          const ContentDetailEvent.submitFeedback(
            contentId: testContentId,
            type: FeedbackType.helpful,
          ),
        ),
        expect: () => [
          ContentDetailState.submittingFeedback(
            content: testContent,
            relatedContent: testRelatedContent,
            userFeedback: null,
            isFavorite: false,
          ),
          const ContentDetailState.error('Failed to submit'),
        ],
      );
    });

    group('ToggleFavorite', () {
      blocTest<ContentDetailBloc, ContentDetailState>(
        'toggles favorite state',
        build: () => bloc,
        seed: () => ContentDetailState.loaded(
          content: testContent,
          relatedContent: testRelatedContent,
          userFeedback: null,
          isFavorite: false,
        ),
        act: (bloc) => bloc.add(
          const ContentDetailEvent.toggleFavorite(testContentId),
        ),
        expect: () => [
          ContentDetailState.loaded(
            content: testContent,
            relatedContent: testRelatedContent,
            userFeedback: null,
            isFavorite: true,
          ),
        ],
      );
    });
  });
}
