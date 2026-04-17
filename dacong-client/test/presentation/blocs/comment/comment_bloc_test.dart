import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:dacong_client/domain/entities/comment.dart';
import 'package:dacong_client/domain/usecases/comment/get_comments.dart';
import 'package:dacong_client/domain/usecases/comment/submit_comment.dart' as usecases;
import 'package:dacong_client/domain/usecases/comment/like_comment.dart' as usecases;
import 'package:dacong_client/domain/usecases/comment/unlike_comment.dart' as usecases;
import 'package:dacong_client/domain/usecases/comment/report_comment.dart' as usecases;
import 'package:dacong_client/presentation/blocs/comment/comment_bloc.dart';
import 'package:dacong_client/presentation/blocs/comment/comment_event.dart';
import 'package:dacong_client/presentation/blocs/comment/comment_state.dart';
import 'package:dacong_client/core/error/failures.dart';

// Mock classes
class MockGetComments extends Mock implements GetComments {}
class MockSubmitComment extends Mock implements usecases.SubmitComment {}
class MockLikeComment extends Mock implements usecases.LikeComment {}
class MockUnlikeComment extends Mock implements usecases.UnlikeComment {}
class MockReportComment extends Mock implements usecases.ReportComment {}

void main() {
  late CommentBloc bloc;
  late MockGetComments mockGetComments;
  late MockSubmitComment mockSubmitComment;
  late MockLikeComment mockLikeComment;
  late MockUnlikeComment mockUnlikeComment;
  late MockReportComment mockReportComment;

  setUp(() {
    mockGetComments = MockGetComments();
    mockSubmitComment = MockSubmitComment();
    mockLikeComment = MockLikeComment();
    mockUnlikeComment = MockUnlikeComment();
    mockReportComment = MockReportComment();

    bloc = CommentBloc(
      getComments: mockGetComments,
      submitComment: mockSubmitComment,
      likeComment: mockLikeComment,
      unlikeComment: mockUnlikeComment,
      reportComment: mockReportComment,
    );
  });

  tearDown(() {
    bloc.close();
  });

  final tContentId = 'content-123';
  final tComment = Comment(
    id: 'comment-1',
    contentId: tContentId,
    userId: 'user-1',
    content: 'Test comment',
    likesCount: 5,
    replyCount: 2,
    isLiked: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('LoadComments', () {
    test('initial state should be CommentInitial', () {
      expect(bloc.state, equals(CommentInitial()));
    });

    blocTest<CommentBloc, CommentState>(
      'emits [CommentLoading, CommentLoaded] when LoadComments succeeds',
      build: () {
        when(() => mockGetComments(
              contentId: any(named: 'contentId'),
              parentId: any(named: 'parentId'),
              page: any(named: 'page'),
              sort: any(named: 'sort'),
            )).thenAnswer((_) async => Right([tComment]));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadComments(contentId: tContentId)),
      expect: () => [
        CommentLoading(),
        CommentLoaded(
          comments: [tComment],
          currentPage: 1,
          hasMore: false,
          sort: 'latest',
        ),
      ],
    );

    blocTest<CommentBloc, CommentState>(
      'emits [CommentLoading, CommentError] when LoadComments fails',
      build: () {
        when(() => mockGetComments(
              contentId: any(named: 'contentId'),
              parentId: any(named: 'parentId'),
              page: any(named: 'page'),
              sort: any(named: 'sort'),
            )).thenAnswer((_) async => Left(ServerFailure('Server error')));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadComments(contentId: tContentId)),
      expect: () => [
        CommentLoading(),
        CommentError(message: 'Server error'),
      ],
    );
  });

  group('SubmitComment', () {
    blocTest<CommentBloc, CommentState>(
      'emits [CommentSubmitting, CommentSubmitted, CommentLoaded] when SubmitComment succeeds',
      build: () {
        when(() => mockSubmitComment(
              contentId: any(named: 'contentId'),
              content: any(named: 'content'),
              parentId: any(named: 'parentId'),
            )).thenAnswer((_) async => Right(tComment));
        return bloc;
      },
      act: (bloc) => bloc.add(SubmitComment(
        contentId: tContentId,
        content: 'New comment',
      )),
      expect: () => [
        CommentSubmitting([]),
        CommentSubmitted(
          newComment: tComment,
          allComments: [tComment],
        ),
        CommentLoaded(
          comments: [tComment],
          currentPage: 1,
          hasMore: true,
          sort: 'latest',
        ),
      ],
    );

    blocTest<CommentBloc, CommentState>(
      'emits [CommentSubmitting, CommentError] when SubmitComment fails',
      build: () {
        when(() => mockSubmitComment(
              contentId: any(named: 'contentId'),
              content: any(named: 'content'),
              parentId: any(named: 'parentId'),
            )).thenAnswer((_) async => Left(ServerFailure('Failed to submit')));
        return bloc;
      },
      act: (bloc) => bloc.add(SubmitComment(
        contentId: tContentId,
        content: 'New comment',
      )),
      expect: () => [
        CommentSubmitting([]),
        CommentError(
          message: 'Failed to submit',
          existingComments: [],
        ),
      ],
    );
  });

  group('LikeComment', () {
    blocTest<CommentBloc, CommentState>(
      'updates comment like status optimistically',
      build: () {
        when(() => mockLikeComment(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => CommentLoaded(
        comments: [tComment],
        currentPage: 1,
        hasMore: false,
        sort: 'latest',
      ),
      act: (bloc) => bloc.add(LikeComment(tComment.id)),
      expect: () => [
        CommentLoaded(
          comments: [
            tComment.copyWith(
              isLiked: true,
              likesCount: tComment.likesCount + 1,
            ),
          ],
          currentPage: 1,
          hasMore: false,
          sort: 'latest',
        ),
      ],
    );
  });

  group('UnlikeComment', () {
    final tLikedComment = tComment.copyWith(isLiked: true, likesCount: 6);

    blocTest<CommentBloc, CommentState>(
      'updates comment unlike status optimistically',
      build: () {
        when(() => mockUnlikeComment(any()))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => CommentLoaded(
        comments: [tLikedComment],
        currentPage: 1,
        hasMore: false,
        sort: 'latest',
      ),
      act: (bloc) => bloc.add(UnlikeComment(tLikedComment.id)),
      expect: () => [
        CommentLoaded(
          comments: [
            tLikedComment.copyWith(
              isLiked: false,
              likesCount: tLikedComment.likesCount - 1,
            ),
          ],
          currentPage: 1,
          hasMore: false,
          sort: 'latest',
        ),
      ],
    );
  });

  group('ReportComment', () {
    blocTest<CommentBloc, CommentState>(
      'emits [CommentActionSuccess, CommentLoaded] when ReportComment succeeds',
      build: () {
        when(() => mockReportComment(
              commentId: any(named: 'commentId'),
              reason: any(named: 'reason'),
            )).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => CommentLoaded(
        comments: [tComment],
        currentPage: 1,
        hasMore: false,
        sort: 'latest',
      ),
      act: (bloc) => bloc.add(ReportComment(commentId: tComment.id)),
      expect: () => [
        CommentActionSuccess(
          message: 'Comment reported successfully',
          comments: [tComment],
        ),
        CommentLoaded(
          comments: [tComment],
          currentPage: 1,
          hasMore: false,
          sort: 'latest',
        ),
      ],
    );
  });
}
